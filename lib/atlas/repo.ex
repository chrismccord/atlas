defmodule Atlas.Repo do
  alias Atlas.Database
  alias Atlas.Database.Client
  alias Atlas.Query
  alias Atlas.Exceptions.AdapterError

  defmacro __using__(options) do
    quote do
      adapter = Keyword.fetch! unquote(options), :adapter
      use Atlas.Query.Processor, adapter: adapter
      use Atlas.Persistence

      def start_link do
        Atlas.Repo.start_link(__MODULE__)
      end

      def stop do
        Atlas.Repo.stop(__MODULE__)
      end

      def database_config do
        config(Mix.env) ++ [adapter: adapter]
      end

      @doc """
      The unique identifier of the repo's genserver adapter process
      """
      def server_name do
        String.to_atom  "repo_server_#{String.downcase(to_string(unquote(__MODULE__)))}"
      end

      @doc """
      Finds the model record when given previous query scope or base Model and value of primary key

      Returns the model Struct if exists in database, nil otherwise

      Examples

        iex> Repo.find(User, 1)
        %User{id: 1...}
        iex> Repo.find(User, 0)
        nil

        iex> Repo.find(User.admins, 1)
        %User{id: 1..., is_site_admin: true}
        iex> Repo.find(User.admins, 0)
        nil

      """
      def find(%Query{} = query, primary_key_value) do
        query |> query.model.where([{query.model.primary_key, primary_key_value}]) |> first
      end
      def find(model, primary_key_value) do
        model.where([{model.primary_key, primary_key_value}]) |> first
      end

      @doc """
      Execute Query expression with adapter and return integer count of records from database.
      If Model is provided instead of Query expression, converts model to query and returns first
      result.

      Examples

        iex> Repo.count User
        123
        iex> Repo.count User.where(admin: true)
        8

      """
      def count(%Query{} = query) do
        query = %Query{query | count: true, order_by: nil, order_by_direction: nil}
        {sql, args} = query |> to_prepared_sql(query.model)

        case Client.execute_prepared_query(sql, args, __MODULE__) do
          {:ok, results} ->
            results
            |> List.first
            |> Keyword.get(:count)
            |> Integer.parse
            |> elem(0)

          {:error, reason} -> raise AdapterError.new(message: inspect(reason))
        end
      end
      def count(model), do: count(to_query(model))

      @doc """
      Execute Query expression with adapter and return database results as normalized
      `model` instances

      Examples

        iex> Repo.all User
        [%User{id: 1...}, %User{id: 2...}]...
        iex> Repo.all User.where(admin: true)
        [%User{id: 10, admin: true...}, %User{id: 22, admin: true...}]

      """
      def all(%Query{} = query) do
        query
        |> to_prepared_sql(query.model)
        |> find_by_sql(query.model, query.includes)
      end
      def all(model), do: all(to_query(model))

      @doc """
      'Low level' database access for executing raw prepared SQL against the database.
      Returns results as normalized as `model` instances.

      Examples

        iex> Repo.find_by_sql({"SELECT * FROM users where id = ?", [1]} User)
        [User.Repo[id: 1...]]

      """
      def find_by_sql({sql, bound_args}, model, []) do
        case Client.execute_prepared_query(sql, bound_args, __MODULE__) do
          {:ok, results}   -> results |> model.raw_query_results_to_records
          {:error, reason} -> raise AdapterError.new(message: inspect(reason))
        end
      end
      def find_by_sql({sql, bound_args}, model, includes) when is_list(includes) do
        find_by_sql({sql, bound_args}, model, [])
        |> records_with_preloaded_includes(model, includes)
      end

      defp records_with_preloaded_includes(records, model, includes) do
        record_ids = Enum.map records, &model.primary_key_value(&1)

        Enum.reduce includes, records, fn {_from_model, relation}, records ->
          preloaded_records = all(relation.model.where([{relation.foreign_key, record_ids}]))

          records
          |> Enum.map(&apply_preloads_to_record(&1, preloaded_records, model, relation))
        end
      end

      defp apply_preloads_to_record(record, preloaded_records, model, relation) do
        record_preloads = Enum.filter_map(preloaded_records, fn inc_rec ->
          apply(relation.model, relation.foreign_key, [inc_rec]) == model.primary_key_value(record)
        end, fn inc_rec ->
          relation_name_for_model = relation.model.find_relationship(model).name
          inc_rec.__preloaded__(apply(inc_rec.__preloaded__, relation_name_for_model, [record]))
        end)

        if Enum.any? record_preloads do
          preloaded_association = apply(record.__preloaded__, relation.name, [record_preloads])
          %{record | __preloaded__: preloaded_association}
        else
          record
        end
      end

      @doc """
      Execute Query expression with adapter, limiting result set to one.
      If Model is provided in place of Query expression, converts model to query.

      Returns the first result as normalized `model` instance from `query.model.table`

      Examples

        iex> Repo.first User
        %User{id: 1...}
        iex> Repo.first User.where(email: "foo@bar.com")
        %User{id: 1..., email: "foo@bar.com"}

      """
      def first(%Query{} = query) do
        %Query{query | limit: 1} |> all |> List.first
      end
      def first(model), do: first(to_query(model))

      @doc """
      Execute Query expression with adapter, limiting results to one and swapping order direction.
      If Model is provided in place of Query expression, converts model to query.

      Returns the first result as normalized `model` instance from `query.model.table`

      Examples

        iex> Repo.last User
        %User{id: 1...}
        iex> Repo.last User.where(email: "foo@bar.com").order(id: :desc)
        %User{id: 1..., email: "foo@bar.com"}

      """
      def last(%Query{} = query) do
        %{query | limit: 1} |> swap_order_direction |> all |> List.first
      end
      def last(model), do: last(to_query(model))

      defp to_query(%Query{} = query), do: query
      defp to_query(model), do: to_query(model.scoped)

      defp swap_order_direction(query) do
        direction = case query.order_by_direction do
          :asc  -> :desc
          :desc -> :asc
          _ -> :desc
        end

        %{query | order_by_direction: direction}
      end
    end
  end

  def start_link(repo) do
    Database.Supervisor.start_link(repo)
  end

  def stop(repo) do
    Database.Supervisor.stop(repo)
  end
end
