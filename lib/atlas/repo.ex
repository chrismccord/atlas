defmodule Atlas.Repo do
  alias Atlas.Database
  alias Atlas.Database.Client
  alias Atlas.Query.Query

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

      def server_name do
        binary_to_atom  "repo_server_#{String.downcase(to_binary(__MODULE__))}"
      end


      @doc """
      Finds the model record when given previous query scope and value of primary key

      Returns the namespaced model.Record if exists in database, nil otherwise

      Examples

        iex> Repo.find(User.admins, 1)
        User.Record[id: 1..., is_site_admin: true]
        iex> Repo.find(User.admins, 0)
        nil
      """
      def find(query = Query[], primary_key_value) do
        query |> query.model.where([{query.model.primary_key, primary_key_value}]) |> first
      end

      @doc """
      Finds the model record when given value of primary key

      Returns the namespaced model.Record if exists in database, nil otherwise

      Examples

        iex> Repo.find(User, 1)
        User.Record[id: 1...]
        iex> Repo.find(User, 0)
        nil
      """
      def find(model, primary_key_value) do
        model.where([{model.primary_key, primary_key_value}]) |> first
      end

      def count(query = Query[]) do
        query = query.update(count: true, order_by: nil, order_by_direction: nil)
        {sql, args} = query |> to_prepared_sql(query.model)
        {:ok, results} = Client.execute_prepared_query(sql, args, __MODULE__)

        results
        |> Enum.first
        |> Keyword.get(:count)
        |> binary_to_integer
      end
      def count(model), do: count(to_query(model))

      def all(query = Query[]) do
        query
        |> to_prepared_sql(query.model)
        |> find_by_sql(query.model)
      end
      def all(model), do: all(to_query(model))

      def find_by_sql({sql, bound_args}, model) do
        {:ok, results} = Client.execute_prepared_query(sql, bound_args, __MODULE__)
        results |> model.raw_query_results_to_records
      end

      def first(query = Query[]) do
        query.limit(1) |> all |> Enum.first
      end
      def first(model), do: first(to_query(model))

      def last(query = Query[]) do
        query.update(limit: 1) |> swap_order_direction |> all |> Enum.first
      end
      def last(model), do: last(to_query(model))

      def to_query(query = Query[]), do: query
      def to_query(model), do: to_query(model.scoped)

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

  def stop(_repo) do
  end
end