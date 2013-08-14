defmodule Atlas.Persistence do
  alias Atlas.Query.Query
  alias Atlas.Database.Client

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do

      def persisted?(record, model) do
        model.primary_key_value(record) != nil
      end

      @doc """
      Updates the record within the `model.table` database table running model validations.
      Keyword list of attributes can be provided corresponding to named schema fields

      Examples

        iex> user = Repo.first User
        iex> Repo.update(User, user, age: 10)
        {:ok, User.Record[age: 10..]}

        iex> Repo.update(User, user, age: 0)
        {:error, User.Record[age: 0..], ["age must be between 1 and 150"]}
      """
      def update(model, record, attributes // []) do
        if Enum.any?(attributes), do: record = record.update(attributes)
        case model.validate(record) do
          {:ok, record } ->
            {sql, args} = to_prepared_update_sql(record, model)
            {:ok, _} = Client.execute_prepared_query(sql, args, __MODULE__)
            {:ok, record}

          {:error, record, reasons} -> {:error, record, reasons}
        end
      end

      # # TODO: only update changed records - Dirty tracking?
      # def save(record) do
      #   if persisted? record do
      #     update(record, to_list(record))
      #   else
      #     create(record)
      #   end
      # end

      @doc """
      Inserts a new record in Repo's database into `model.table` provided Keyword list of attributes
      or `model.Record` instance.

      Examples

        iex> Repo.create(User, age: 12)
        {:ok, User.Record[age: 12...]}

        iex> Repo.create(User, User.Recod.new(age: 18))
        {:ok, User.Record[age: 18...]}

        iex> Repo.create(User, age: 0)
        {:error, User.Record[age: 0..], ["age must be between 1 and 150"]}
      """
      def create(model, attributes) when is_list(attributes) do
        create model, model.Record.new(attributes)
      end
      def create(model, record) when is_record(record) do
        case model.validate(record) do
          {:ok, record} ->
            {sql, args} = to_prepared_insert_sql(record, model)
            {:ok, [[{_pkey, pkey_value}]]} = Client.execute_prepared_query(sql, args, __MODULE__)

            {:ok, record.update(model.raw_kwlist_to_field_types([{_pkey, pkey_value}]))}

          {:error, record, reasons} -> {:error, record, reasons}
        end
      end

      @doc """
      Deletes record from Repo's database in `model.table` matching record's primary key value.

      Examples
        iex> user = User.first
        User.Record[id: 123]
        iex> Repo.destroy User, user
        {:ok, User.Record[id: nil]}
      """
      def destroy(model, record) do
        {sql, args} = to_prepared_delete_sql(record, model)
        case Client.execute_prepared_query(sql, args, __MODULE__) do
          {:ok, _ }        -> {:ok, record.update([{model.primary_key, nil}])}
          {:error, reason} -> {:error, reason}
        end
      end

      @doc """
      Deletes all records from Repo's database in `model.table` matching records' primary key values

      Examples
        iex> trashed_users = User.where(archived: true) |> Repo.all
        [User.Record[id: 123], User.Record[id: 124], User.Record[id: 125]...]
        iex> Repo.destroy_all trashed_users
        {:ok, []}
      """
      def destroy_all(records, model) when is_list(records) do
        ids = Enum.map records, &model.primary_key_value(&1)
        destroy_all(model.where([{model.primary_key, ids}]))
      end
      def destroy_all(query = Query[]) do
        {sql, args} = to_prepared_delete_sql(query, query.model)
        {:ok, _} = Client.execute_prepared_query(sql, args, __MODULE__)
      end

      defp attributes_without_nil_primary_key(record, model) do
        if model.primary_key_value(record) do
          model.to_list(record)
        else
          record
          |> model.to_list
          |> Keyword.delete_first(model.primary_key)
        end
      end

      defp to_set_sql(attributes) do
        attributes
        |> Keyword.keys
        |> Enum.map(fn column -> "#{adapter.quote_column(column)} = ?" end)
        |> Enum.join(", ")
      end

      defp to_column_sql(attributes) do
        attributes
        |> Keyword.keys
        |> Enum.map(fn column -> "#{adapter.quote_column(column)}" end)
        |> Enum.join(", ")
      end

      defp to_prepared_update_sql(record, model) do
        attributes = Atlas.Record.to_list(record)
        prepared_sql = """
        UPDATE #{adapter.quote_tablename(model.table)}
        SET #{to_set_sql(attributes)}
        WHERE #{adapter.quote_tablename(model.table)}.#{adapter.quote_column(model.primary_key)} = ?
        """

        { prepared_sql, Keyword.values(attributes) ++ [model.primary_key_value(record)] }
      end

      defp to_prepared_insert_sql(record, model) do
        attributes = attributes_without_nil_primary_key(record, model)

        prepared_sql = """
        INSERT INTO #{adapter.quote_tablename(model.table)}
        (#{to_column_sql(attributes)})
        VALUES(?)
        RETURNING #{adapter.quote_column(model.primary_key)}
        """

        { prepared_sql, [Keyword.values(attributes)] }
      end

      defp to_prepared_delete_sql(query = Query[], model) do
        ids = query |> all |> Enum.map(model.primary_key_value(&1))

        prepared_sql = """
        DELETE FROM #{adapter.quote_tablename(model.table)}
        WHERE #{adapter.quote_tablename(model.table)}.#{adapter.quote_column(model.primary_key)}
        IN(?)
        """

        {prepared_sql, [ids]}
      end
      defp to_prepared_delete_sql(record, model) do
        prepared_sql = """
        DELETE FROM #{adapter.quote_tablename(model.table)}
        WHERE #{adapter.quote_tablename(model.table)}.#{adapter.quote_column(model.primary_key)} = ?
        """

        {prepared_sql, [model.primary_key_value(record)]}
      end
    end
  end
end