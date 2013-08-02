defmodule Atlas.QueryBuilder.RelationProcessor do
  alias Atlas.Database.Client
  alias Atlas.QueryBuilder.Relation

  import Client, only: [adapter: 0]

  def select_to_sql(relation = Relation[select: nil, count: true]) do
    "COUNT(#{quote_tablename(relation)}.*)"
  end
  def select_to_sql(relation = Relation[select: nil]) do
    "#{quote_tablename(relation)}.*"
  end
  def select_to_sql(relation = Relation[count: true]) do
    "COUNT(#{quote_tablename(relation)}.#{relation.select})"
  end
  def select_to_sql(relation) do
    "#{quote_tablename(relation)}.#{relation.select}"
  end

  def wheres_to_sql(relation) do
    if Enum.count(relation.wheres) > 0 do
      "WHERE " <> (relation.wheres |> Enum.map_join(" AND ", fn {query, _} -> "(#{query})" end))
    end
  end

  def order_by_to_sql(relation) do
    Relation[order_by: order_by, order_by_direction: direction] = relation
    if order_by do
      """
      ORDER BY #{order_by}#{if direction, do: " #{String.upcase to_binary(direction)}"}
      """
    end
  end

  def limit_to_sql(relation) do
    if relation.limit, do: "LIMIT #{relation.limit}"
  end

  def bound_arguments(relation) do
    relation.wheres
    |> Enum.map(fn {_query, values} -> values end)
    |> List.flatten
  end

  def to_prepared_sql(relation) do
    select     = select_to_sql(relation)
    from       = quote_tablename(relation)
    wheres     = wheres_to_sql(relation)
    bound_args = bound_arguments(relation)

    prepared_sql = """
    SELECT #{select} FROM #{from}
    #{wheres}
    #{order_by_to_sql(relation)}
    #{limit_to_sql(relation)}
    """

    { prepared_sql, bound_args}
  end

  defp quote_tablename(relation), do: adapter.quote_tablename(relation.from)
end