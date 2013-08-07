defmodule Atlas.Persistence do
  alias Atlas.Database.Client
  alias Atlas.QueryBuilder.Relation
  import Client, only: [adapter: 0]


  def to_set_sql(attributes) do
    attributes
    |> Keyword.keys
    |> Enum.map(fn column -> "#{adapter.quote_column(column)} = ?" end)
    |> Enum.join(", ")
  end

  def to_column_sql(attributes) do
    attributes
    |> Keyword.keys
    |> Enum.map(fn column -> "#{adapter.quote_column(column)}" end)
    |> Enum.join(", ")
  end

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do

      def persisted?(record) do
        primary_key_value(record) != nil
      end

      defp attributes_without_nil_primary_key(record) do
        if primary_key_value(record) do
          to_list(record)
        else
          record
          |> to_list
          |> Keyword.delete_first(@primary_key)
        end
      end

      def to_prepared_update_sql(record, attributes) do
        prepared_sql = """
        UPDATE #{adapter.quote_tablename(@table)}
        SET #{to_set_sql(attributes)}
        WHERE #{adapter.quote_tablename(@table)}.#{adapter.quote_column(@primary_key)} = ?
        """

        { prepared_sql, Keyword.values(attributes) ++ [primary_key_value(record)] }
      end

      def to_prepared_insert_sql(record) do
        attributes = attributes_without_nil_primary_key(record)

        prepared_sql = """
        INSERT INTO #{adapter.quote_tablename(@table)}
        (#{to_column_sql(attributes)})
        VALUES(?)
        RETURNING #{adapter.quote_column(@primary_key)}
        """

        { prepared_sql, [Keyword.values(attributes)] }
      end

      def to_prepared_delete_sql(record = __MODULE__.Record[]) do
        prepared_sql = """
        DELETE FROM #{adapter.quote_tablename(@table)}
        WHERE #{adapter.quote_tablename(@table)}.#{adapter.quote_column(@primary_key)} = ?
        """

        {prepared_sql, [primary_key_value(record)]}
      end
      def to_prepared_delete_sql(relation = Relation[]) do
        ids = relation |> to_records |> Enum.map(primary_key_value(&1))

        prepared_sql = """
        DELETE FROM #{adapter.quote_tablename(@table)}
        WHERE #{adapter.quote_tablename(@table)}.#{adapter.quote_column(@primary_key)}
        IN(?)
        """

        {prepared_sql, [ids]}
      end

      def update(record, attributes) do
        record = record.update(attributes)
        if valid?(record) do
          {sql, args} = to_prepared_update_sql(record, attributes)
          {:ok, _} = Client.execute_prepared_query(sql, args)
          {:ok, record}
        else
          {:error, record, errors(record)}
        end
      end

      # TODO: only update changed records - Dirty tracking?
      def save(record) do
        if persisted? record do
          update(record, to_list(record))
        else
          create(record)
        end
      end

      def create(attributes) when is_list(attributes) do
        create __MODULE__.Record.new(attributes)
      end
      def create(record) when is_record(record) do
        if valid?(record) do
          {sql, args} = to_prepared_insert_sql(record)
          {:ok, [[{@primary_key, pkey_value}]]} = Client.execute_prepared_query(sql, args)

          {:ok, record.update(raw_kwlist_to_field_types([{@primary_key, pkey_value}]))}
        else
          {:error, errors(record)}
        end
      end

      def destroy(record) do
        {sql, args} = to_prepared_delete_sql(record)
        case Client.execute_prepared_query(sql, args) do
          {:ok, _ }        -> {:ok, record.update([{@primary_key, nil}])}
          {:error, reason} -> {:error, reason}
        end
      end

      # def destroy_all(records) when is_list(records) do
      #   destroy_all(where("id IN ?"))
      # end
      def destroy_all(relation = Relation[]) do
        {sql, args} = to_prepared_delete_sql(relation)
        {:ok, _} = Client.execute_prepared_query(sql, args)
      end
    end
  end
end