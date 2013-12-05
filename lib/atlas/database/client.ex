defmodule Atlas.Database.Client do
  alias Atlas.Logger

  def raw_query(string, repo) do
    Logger.debug(String.replace(string, "\n", ""), repo)
    :gen_server.call repo.server_name, {:execute_query, string}
  end

  def raw_prepared_query(string, args, repo) do
    Logger.debug("#{String.replace(string, "\n", " ")}, #{inspect args}", repo)
    :gen_server.call repo.server_name, {:execute_prepared_query, string, args}
  end

  def execute_query(query_string, repo) do
    case raw_query(query_string, repo) do
      {:ok, {_, cols, rows}} -> {:ok, keyword_lists_from_query(cols, rows)}
      {:error, reason}       -> {:error, reason}
    end
  end

  def execute_prepared_query(query_string, args, repo) do
    case raw_prepared_query(query_string, args, repo) do
      {:ok, {_, cols, rows}} -> {:ok, keyword_lists_from_query(cols, rows)}
      {:error, reason}       -> {:error, reason}
    end
  end

  defp keyword_lists_from_query(columns, rows) do
    Enum.map rows, &Enum.zip(columns, &1)
  end
end
