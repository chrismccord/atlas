defmodule Atlas.QueryBuilder do

  defrecord Relation, froms: [], wheres: [], selects: [], includes: [], joins: []


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

  def kwlist_to_bound_query(equalities) do
    {query_strings, values} = equalities
    |> Enum.with_index
    |> Enum.reverse
    |> Enum.map(fn {{key, val}, index} ->
        if index > 0 do
          {"AND #{key} = ?", val}
        else
          {"#{key} = ?", val}
        end
      end)
    |> Enum.reduce({[], []}, fn {query_string, value}, {query_acc, values} ->
      {[query_string | query_acc], [value | values]}
    end)

    {Enum.join(query_strings, " \n"), values}
  end
end