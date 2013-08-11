defmodule Atlas.Query.Processor do
  alias Atlas.Query.Query

  defmacro __using__(options) do
    quote do
      @adapter Keyword.fetch! unquote(options), :adapter

      def adapter, do: @adapter

      def select_to_sql(query = Query[select: nil, count: true], model) do
        "COUNT(#{adapter.quote_tablename(model.table)}.*)"
      end
      def select_to_sql(query = Query[select: nil], model) do
        "#{adapter.quote_tablename(model.table)}.*"
      end
      def select_to_sql(query = Query[count: true], model) do
        "COUNT(#{adapter.quote_tablename(model.table)}.#{adapter.quote_column(query.select)})"
      end
      def select_to_sql(query, model) do
        "#{adapter.quote_tablename(model.table)}.#{adapter.quote_column(query.select)}"
      end

      def wheres_to_sql(Query[wheres: []], model), do: nil
      def wheres_to_sql(query, model) do
        "WHERE " <> join_wheres_with(query.wheres, "AND")
      end

      defp join_wheres_with(wheres, operator) do
        Enum.map_join(wheres, " #{operator} ", fn {query, _} -> "(#{query})" end)
      end

      def order_by_to_sql(query) do
        Query[order_by: order_by, order_by_direction: direction] = query
        if order_by do
          """
          ORDER BY #{order_by}#{if direction, do: " #{String.upcase to_binary(direction)}"}
          """
        end
      end

      def limit_to_sql(Query[limit: nil]), do: nil
      def limit_to_sql(query), do: "LIMIT #{query.limit}"

      def offset_to_sql(Query[offset: nil]), do: nil
      def offset_to_sql(query), do: "OFFSET #{query.offset}"

      def bound_arguments(query) do
        query.wheres
        |> Enum.map(fn {_query, values} -> values end)
        |> Enum.reduce([], fn value, acc -> acc ++ value end)
      end

      defp normalize_query_for_sql(query, model) do
        query.update(wheres: normalize_wheres(query, model))
      end

      @doc """
      Convert wheres list of query to bound SQL fragments when where fragment is kwlist of
      expressions.

      Examples

        iex> normalize_wheres(Query[ wheres: [name: "Elixir"] ], User)
        [WHERE "table"."name" = ?, ["Elixir"]]

        iex> normalize_wheres(Query[ wheres: ["table.name = ?", "Elixir"] ], User)
        [WHERE table.name = ?, ["Elixir"]]
      """
      def normalize_wheres(query, model) do
        Enum.map query.wheres, fn where ->
          if Keyword.keyword?(where) do
            kwlist_to_bound_query(where, model)
          else
            where
          end
        end
      end

      def to_prepared_sql(query, model) do
        query      = normalize_query_for_sql(query, model)
        select     = select_to_sql(query, model)
        from       = adapter.quote_tablename(model.table)
        wheres     = wheres_to_sql(query, model)
        bound_args = bound_arguments(query)

        prepared_sql = """
        SELECT #{select} FROM #{from}
        #{wheres}
        #{order_by_to_sql(query)}
        #{limit_to_sql(query)}
        #{offset_to_sql(query)}
        """

        { prepared_sql, bound_args}
      end

      @doc """
      Convert a keyword list of key, val equalities into prepared sql bound query

      Examples
      ```
      kwlist_to_bound_query(email: "foo@bar.com", archived: [false])
      { "\"users\".\"email\" = ? AND \"users\".\"archived\" IN(?, ?)", ["foo@bar.com, false] }
      ```

      Returns Tuple { bound_query_string, bound_values }
      """
      def kwlist_to_bound_query(equalities, model) do
        {query_strings, values} = equalities
        |> Enum.with_index
        |> Enum.reverse
        |> Enum.map(equality_to_bound_query(&1, model))
        |> Enum.reduce({[], []}, fn {query_string, value}, {query_acc, values} ->
          {[query_string | query_acc], [value | values]}
        end)

        {Enum.join(query_strings, " \n"), values}
      end
      defp equality_to_bound_query({{key, values}, index}, model) when is_list(values) do
        cast_values = Enum.map values, fn value ->
          model.value_to_field_type(value, model.field_type_for_name(key))
        end
        if index > 0 do
          {"AND #{adapter.quote_namespaced_column(model.table, key)} IN(?)", cast_values}
        else
          {"#{adapter.quote_namespaced_column(model.table, key)} IN(?)", cast_values}
        end
      end
      defp equality_to_bound_query({{key, value}, index}, model) do
        cast_val = model.value_to_field_type(value, model.field_type_for_name(key))
        if index > 0 do
          {"AND #{adapter.quote_namespaced_column(model.table, key)} = ?", cast_val}
        else
          {"#{adapter.quote_namespaced_column(model.table, key)} = ?", cast_val}
        end
      end
    end
  end
end