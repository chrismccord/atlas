defmodule Atlas.Database.Client do

  def query(string) do
    :gen_server.call :db_server, {:query, string}
  end

  def map_query_to_records(query_string, record) do
    {:ok, count, columns, rows} = query(query_string)

    keyword_lists_from_query(columns, rows)
    |> keyword_lists_to_records(record)
  end

  def keyword_lists_from_query(columns, rows) do
    Enum.map rows, Enum.zip(columns, &1)
  end

  def keyword_lists_to_records(kwlists, record) do
    Enum.map kwlists, fn row -> record.new(row) end
  end
end
