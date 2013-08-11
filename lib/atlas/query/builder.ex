defmodule Atlas.Query.Builder do
  alias Atlas.Query.Query

  @doc """
  Converts list into comma delimited binding placeholders for query.
  Useful when transforming list into query bindings

  Examples

    iex> Model.list_to_binding_placeholders([1,2,3])
    "?, ?, ?"
  """
  def list_to_binding_placeholders([]), do: ""
  def list_to_binding_placeholders(collection) do
    1..Enum.count(collection)
    |> Enum.map_join(", ", fn _ -> "?" end)
  end

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def new_base_query do
        Query.new(model: __MODULE__, from: @table)
      end

      def scoped do
        new_base_query
      end

      def where(kwlist) when is_list(kwlist) do
        where new_base_query, kwlist
      end
      def where(query = Query[], kwlist) when is_list(kwlist) do
        query.wheres(query.wheres ++ [kwlist])
      end

      def where(query_string, values) when is_binary(query_string) do
        where new_base_query, query_string, List.flatten([values])
      end
      def where(query = Query[], query_string, values) when is_binary(query_string) do
        query.wheres(query.wheres ++ [{query_string, List.flatten([values])}])
      end
      def where(query_string) when is_binary(query_string) do
        where(query_string, [])
      end
      def where(query = Query[], query_string) when is_binary(query_string) do
        where(query, query_string, [])
      end

      # def first do
      #   new_base_query
      # end

      # def last do
      #   new_base_query
      # end

      def order(options) do
        order new_base_query, options
      end
      def order(query, field) when is_atom(field) or is_binary(field) do
        query.order_by(field)
      end
      def order(query, [{field, direction}]) do
        query.update(order_by: field, order_by_direction: direction)
      end
      def order_direction(query, direction) do
        query.order_by_direction(direction)
      end

      def limit(number) do
        limit new_base_query, number
      end
      def limit(query, number) do
        query.limit(number)
      end

      def offset(number) do
        offset new_base_query, number
      end
      def offset(query, number) do
        query.offset(number)
      end

      def select(column), do: select(new_base_query, column)
      def select(query, column) do
        query.select(to_binary(column))
      end

      # def count, do: count(new_base_query)
    end
  end
end
