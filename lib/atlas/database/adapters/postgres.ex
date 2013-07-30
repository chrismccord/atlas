defmodule Atlas.Database.PostgresAdapter do
  @behaviour Atlas.Database.Adapter

  import Atlas.Database.FieldNormalizer
  alias :pgsql, as: PG

  def connect(config) do
    case PG.connect(
      binary_to_list(config.host),
      binary_to_list(config.username),
      binary_to_list(config.password),
      database: binary_to_list(config.database)) do

      {:ok, pid}       -> {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end

  def execute_query(pid, string) do
    normalize_results(PG.squery(pid, string))
  end

  def execute_prepared_query(pid, query_string, args) do
    normalize_results(PG.equery(pid, convert_bindings_to_native_format(query_string), args))
  end
  defp normalize_results(results) do
    case results do
      {:ok, cols, rows}        -> {:ok, {nil, normalize_cols(cols), normalize_rows(rows)}}
      {:ok, count}             -> {:ok, {count, [], []}}
      {:ok, count, cols, rows} -> {:ok, {count, normalize_cols(cols), normalize_rows(rows)}}
      {:error, error }         -> {:error, error }
    end
  end

  defp convert_bindings_to_native_format(query_string) do
    parts = query_string |> String.split("?")

    parts
    |> Enum.with_index
    |> Enum.map(fn {part, index} ->
         if index < Enum.count(parts) - 1 do
           part <> "$#{index + 1}"
         else
           part
         end
       end)
    |> Enum.join("")
  end

  def quote_column(column), do: "\"#{column}\""

  def quote_tablename(tablename), do: "\"#{tablename}\""

  # Ex: [{:column,"id",:int4,4,-1,0}, {:column,"age",:int4,4,-1,0}]
  # => [:id, :age]
  defp normalize_cols(columns) do
    Enum.map columns, fn col -> binary_to_atom(elem(col, 1)) end
  end

  defp normalize_rows(rows_of_tuples) do
    rows_of_tuples
    |> Enum.map(tuple_to_list(&1))
    |> Enum.map(normalize_values(&1))
  end
end