defmodule Atlas.Repo do
  alias Atlas.Database.Client
  alias Atlas.QueryBuilder.Query

  defmacro __using__(options) do
    quote do
      adapter = Keyword.fetch! unquote(options), :adapter
      use Atlas.QueryBuilder.QueryProcessor, adapter: adapter

      def count(query = Query[]) do
        query = query.update(count: true, order_by: nil, order_by_direction: nil)
        {sql, args} = query |> to_prepared_sql(query.model)
        {:ok, results} = Client.execute_prepared_query(sql, args)

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
        {:ok, results} = Client.execute_prepared_query(sql, bound_args)
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
end

defmodule Repo do
  use Atlas.Repo, adapter: Atlas.Database.PostgresAdapter

end