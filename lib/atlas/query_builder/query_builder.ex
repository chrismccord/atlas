defmodule Atlas.QueryBuilder do
  alias Atlas.Database.Client

  defrecord Relation, froms: [], wheres: [], select: nil, includes: [], joins: [], limit: nil,
                      offset: nil, order_by: nil, order_by_direction: nil, count: false

  defmodule RelationBuilder do
    def select(Relation[select: nil, count: true], quoted_tablename) do
      "COUNT(#{quoted_tablename}.*)"
    end
    def select(Relation[select: nil], quoted_tablename) do
      "#{quoted_tablename}.*"
    end
    def select(relation = Relation[count: true], quoted_tablename) do
      "COUNT(#{quoted_tablename}.#{relation.select})"
    end
    def select(relation, quoted_tablename) do
      "#{quoted_tablename}.#{relation.select}"
    end
  end

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)

      @table nil
      @primary_key nil
      @default_primary_key "id"
      @binding_placeholder "?"

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do


    # Enum.each @fields, fn {field, _} ->
    #   method_name = binary_to_atom("find_by_#{field}")
    #   def method_name, quote(do: [field_value]), [], quote(do:
    #     where({unquote(field), field_value}) |> first
    #   )
    # end

    quote do
      @table to_binary(@table)
      @primary_key to_binary(@primary_key || @default_primary_key)

      def __atlas__(:table), do: @table

      def where(kwlist) when is_list(kwlist) do
        where Relation.new, kwlist
      end
      def where(relation = Relation[], kwlist) when is_list(kwlist) do
        relation.wheres(relation.wheres ++ [kwlist_to_bound_query(kwlist)])
      end

      def where(query_string, values) when is_binary(query_string) do
        where Relation.new, query_string, List.flatten([values])
      end
      def where(relation = Relation[], query_string, values) when is_binary(query_string) do
        relation.wheres(relation.wheres ++ [{query_string, List.flatten([values])}])
      end
      def where(query_string) when is_binary(query_string) do
        where(query_string, [])
      end
      def where(relation = Relation[], query_string) when is_binary(query_string) do
        where(relation, query_string, [])
      end

      def first do
        first Relation.new
      end
      def first(relation) do
        relation.limit(1) |> to_records |> Enum.first
      end

      def last do
        last Relation.new
      end
      def last(relation) do
        relation.update(limit: 1) |> swap_order_direction |> to_records |> Enum.first
      end

      def order(relation, field) when is_atom(field) or is_binary(field) do
        relation.order_by(field)
      end
      def order(relation, [{field, direction}]) do
        relation.update(order_by: field, order_by_direction: direction)
      end
      def order_direction(relation, direction) do
        relation.order_by_direction(direction)
      end
      def swap_order_direction(relation) do
        relation.order_by_direction(case relation.order_by_direction do
          :asc  -> :desc
          :desc -> :asc
          _ -> :desc
        end)
      end

      def select(column), do: select(Relation.new, column)
      def select(relation, column) do
        relation.select(to_binary(column))
      end

      def count, do: count(Relation.new)
      def count(relation) do
        relation.update(count: true, order_by: nil, order_by_direction: nil)
        |> to_sql
        |> Client.query
        |> Enum.first
        |> Keyword.get(:count)
        |> binary_to_integer
      end

      def to_records(relation) do
        relation
        |> to_sql
        |> find_by_sql
      end

      def find_by_sql(sql) do
        sql
        |> Client.query
        |> raw_query_results_to_records
     end

      def kwlist_to_bound_query(equalities) do
        {query_strings, values} = equalities
        |> Enum.with_index
        |> Enum.reverse
        |> Enum.map(fn {{key, val}, index} ->
            cast_val = value_to_field_type(val, field_type_for_name(key))
            if index > 0 do
              {"AND #{quoted_namespaced_column(key)} = ?", cast_val}
            else
              {"#{quoted_namespaced_column(key)} = ?", cast_val}
            end
          end)
        |> Enum.reduce({[], []}, fn {query_string, value}, {query_acc, values} ->
          {[query_string | query_acc], [value | values]}
        end)

        {Enum.join(query_strings, " \n"), values}
      end

      defp quoted_namespaced_column(column) do
        if @table do
          "#{quoted_tablename}.#{adapter.quote_column(column)}"
        else
          adapter.quote_column(column)
        end
      end

      def to_sql(relation) do
        wheres    = relation.wheres |> Enum.map_join(" AND ", binding_to_sql(&1))
        select    = RelationBuilder.select(relation, quoted_tablename)
        """
          SELECT #{select} FROM #{quoted_tablename}
          WHERE
          #{wheres}
          #{order_by_to_sql(relation)}
        """
      end

      def order_by_to_sql(relation) do
        Relation[order_by: order_by, order_by_direction: direction] = relation
        if order_by do
          """
          ORDER BY #{order_by}#{if direction, do: " #{String.upcase to_binary(direction)}"}
          """
        end
      end

      defp binding_to_sql({query_string, values}) do
        query_string = query_string
        |> String.split(@binding_placeholder)
        |> Enum.zip(values)
        |> Enum.map_join("", fn {query, value} ->
          if String.length(query) > 0 do
            case value do
              nil -> query
              _   -> "#{query}#{quote_value(value)}"
            end
          end
        end)

        "(#{query_string})"
      end

      defp quoted_tablename, do: adapter.quote_tablename(@table)
      defp quote_value(value), do: adapter.quote_value(value)
      defp adapter, do: Client.adapter
    end
  end
end
