defmodule Atlas.Database.PostgresAdapter do
  @behaviour Atlas.Database.Adapter
  import Atlas.Query.Builder, only: [list_to_binding_placeholders: 1]
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

  @doc """
  Executes prepared query with adapter after converting Atlas bindings to native formats

  Returns "normalized" results with Elixir specific types coerced from DB binaries
  """
  def execute_prepared_query(pid, query_string, args) do
    args = denormalize_values(args)
    native_bindings = convert_bindings_to_native_format(query_string, args)

    PG.equery(pid, native_bindings, List.flatten(args)) |> normalize_results
  end
  defp normalize_results(results) do
    case results do
      {:ok, cols, rows}        -> {:ok, {nil, normalize_cols(cols), normalize_rows(rows)}}
      {:ok, count}             -> {:ok, {count, [], []}}
      {:ok, count, cols, rows} -> {:ok, {count, normalize_cols(cols), normalize_rows(rows)}}
      {:error, error }         -> {:error, error }
    end
  end


  @doc """
  Convert Atlas query binding syntax to native adapter format.

  Examples
  ```
  iex> convert_bindings_to_native_format("SELECT * FROM users WHERE id = ? AND archived = ?", [1, false])
  SELECT * FROM users WHERE id = $1 AND archived = $2"

  iex> convert_bindings_to_native_format("SELECT * FROM users WHERE id IN(?)", [[1,2,3]])
  SELECT * FROM users WHERE id IN($1, $2, $3)
  """
  def convert_bindings_to_native_format(query_string, args) do
    parts = expand_bindings(query_string, args) |> String.split("?")
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

  @doc """
  Expand binding placeholder "?" into "?, ?, ?..." when binding matches list

  Examples
  ```
  iex> expand_bindings("SELECT * FROM users WHERE id IN(?)", [[1,2,3]])
  "SELECT * FROM users WHERE id IN($1, $2, $3)"
  ```
  """
  def expand_bindings(query_string, args) do
    parts = query_string |> String.split("?") |> Enum.with_index

    expanded_placeholders = Enum.map parts, fn {part, index} ->
      if index < Enum.count(parts) - 1 do
        case Enum.at(args, index) do
          values when is_list(values) -> part <> list_to_binding_placeholders(values)
          value -> part <> "?"
        end
      else
        part
      end
    end

    expanded_placeholders |> Enum.join("")
  end

  def quote_column(column), do: "\"#{column}\""

  def quote_tablename(tablename), do: "\"#{tablename}\""

  def quote_namespaced_column(table, column) do
    if table do
      "#{quote_tablename(table)}.#{quote_column(column)}"
    else
      quote_column(column)
    end
  end

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