defmodule Atlas.Repo do
  alias Atlas.Database
  alias Atlas.Database.Client
  alias Atlas.Query.Query
  alias Atlas.AdapterError

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
        binary_to_atom  "repo_server_#{String.downcase(to_binary(__MODULE__))}"
      end

      @doc """
      Finds the model record when given previous query scope or base Model and value of primary key

      Returns the namespaced model.Record if exists in database, nil otherwise

      Examples

        iex> Repo.find(User, 1)
        User.Record[id: 1...]
        iex> Repo.find(User, 0)
        nil

        iex> Repo.find(User.admins, 1)
        User.Record[id: 1..., is_site_admin: true]
        iex> Repo.find(User.admins, 0)
        nil

      """
      def find(query = Query[], primary_key_value) do
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
      def count(query = Query[]) do
        query = query.update(count: true, order_by: nil, order_by_direction: nil)
        {sql, args} = query |> to_prepared_sql(query.model)

        case Client.execute_prepared_query(sql, args, __MODULE__) do
          {:ok, results} ->
            results
            |> Enum.first
            |> Keyword.get(:count)
            |> binary_to_integer

          {:error, reason} -> raise AdapterError.new(message: inspect(reason))
        end
      end
      def count(model), do: count(to_query(model))

      @doc """
      Execute Quer expression with adapter and return database results as normalized
      `model.Record` instances

      Examples

        iex> Repo.all User
        [User.Record[id: 1...], User.Record[id: 2...]]...
        iex> Repo.all User.where(admin: true)
        [User.Record[id: 10, admin: true...], User.Record[id: 22, admin: true...]]

      """
      def all(query = Query[]) do
        query
        |> to_prepared_sql(query.model)
        |> find_by_sql(query.model)
      end
      def all(model), do: all(to_query(model))

      @doc """
      'Low level' database access for executing raw prepared SQL against the database.
      Returns results as normalized as `model.Record` instances.

      Examples

        iex> Repo.find_by_sql({"SELECT * FROM users where id = ?", [1]} User)
        [User.Repo[id: 1...]]

      """
      def find_by_sql({sql, bound_args}, model) do
        case Client.execute_prepared_query(sql, bound_args, __MODULE__) do
          {:ok, results}   -> results |> model.raw_query_results_to_records
          {:error, reason} -> raise AdapterError.new(message: inspect(reason))
        end
      end

      @doc """
      Execute Query expression with adapter, limiting result set to one.
      If Model is provided in place of Query expression, converts model to query.

      Returns the first result as normalized `model.Record` instance from `query.model.table`

      Examples

        iex> Repo.first User
        User.Repo[id: 1...]
        iex> Repo.first User.where(email: "foo@bar.com")
        User.Repo[id: 1..., email: "foo@bar.com"]

      """
      def first(query = Query[]) do
        query.limit(1) |> all |> Enum.first
      end
      def first(model), do: first(to_query(model))

      @doc """
      Execute Query expression with adapter, limiting results to one and swapping order direction.
      If Model is provided in place of Query expression, converts model to query.

      Returns the first result as normalized `model.Record` instance from `query.model.table`

      Examples

        iex> Repo.last User
        User.Repo[id: 1...]
        iex> Repo.last User.where(email: "foo@bar.com").order(id: :desc)
        User.Repo[id: 1..., email: "foo@bar.com"]

      """
      def last(query = Query[]) do
        query.update(limit: 1) |> swap_order_direction |> all |> Enum.first
      end
      def last(model), do: last(to_query(model))

      defp to_query(query = Query[]), do: query
      defp to_query(model), do: to_query(model.scoped)

      defp swap_order_direction(query) do
        query.order_by_direction(case query.order_by_direction do
          :asc  -> :desc
          :desc -> :asc
          _ -> :desc
        end)
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