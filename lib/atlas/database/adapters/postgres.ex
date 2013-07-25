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

  def query(pid, string) do
    case PG.squery(pid, string) do
      {:ok, cols, rows}        -> {:ok, nil, normalize_cols(cols), normalize_rows(rows)}
      {:ok, count}             -> {:ok, count, [], []}
      {:ok, count, cols, rows} -> {:ok, count, normalize_cols(cols), normalize_rows(rows)}
      {:error, error }         -> {:error, error }
    end
  end

  def quote_column(column), do: "\"#{column}\""

  def quote_tablename(tablename), do: "\"#{tablename}\""

  def quote_value(value), do: "'#{escape value}'"

  def escape(value), do: value

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