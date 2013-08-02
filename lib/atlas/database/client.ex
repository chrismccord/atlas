defmodule Atlas.Database.Client do
  import Atlas, only: [database_config: 0]
  alias Atlas.Logger

  def raw_query(string) do
    Logger.debug(String.replace(string, "\n", ""))
    :gen_server.call :db_server, {:execute_query, string}
  end

  def raw_prepared_query(string, args) do
    Logger.debug("#{String.replace(string, "\n", " ")}, #{inspect args}")
    :gen_server.call :db_server, {:execute_prepared_query, string, args}
  end

  def adapter do
    database_config[:adapter]
  end

  def execute_query(query_string) do
    {:ok, {_count, columns, rows}} = raw_query(query_string)

    keyword_lists_from_query(columns, rows)
  end

  def execute_prepared_query(query_string, args) do
    {:ok, {_count, columns, rows}} = raw_prepared_query(query_string, args)

    keyword_lists_from_query(columns, rows)
  end

  defp keyword_lists_from_query(columns, rows) do
    Enum.map rows, Enum.zip(columns, &1)
  end
end
