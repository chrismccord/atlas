defmodule Atlas.Database.Server do
  use GenServer

  alias Atlas.Database.Server.ConfigInfo
  alias Atlas.Database.Server.Connection

  def start_link(repo) do
    GenServer.start_link(__MODULE__, [repo.database_config], name: repo.server_name)
  end

  def init([config_options]) do
    connections = connect_all(struct(ConfigInfo, config_options))

    {:ok, {connections, List.first(connections)} }
  end

  def handle_call({:execute_query, string}, _from, {connections, conn}) do
    {
      :reply,
      execute_query(conn, string),
      {connections, next_conn(connections, conn)}
    }
  end

  def handle_call({:execute_prepared_query, string, args}, _from, {connections, conn}) do
    {
      :reply,
      execute_prepared_query(conn, string, args),
      {connections, next_conn(connections, conn)}
    }
  end

  defp connect_all(config) do
    Enum.map 1..(config.pool), fn _pool ->
      {:ok, pid} = connect(config)
      %Connection{pid: pid, adapter: config.adapter}
    end
  end

  defp next_conn(connections, current_connection) do
    index = Enum.find_index(connections, &(&1 == current_connection))
    if index == Enum.count(connections) - 1 do
      List.first(connections)
    else
      Enum.at(connections, index + 1)
    end
  end

  defp connect(config) do
    config.adapter.connect(config)
  end

  defp execute_query(conn, string) do
    conn.adapter.execute_query(conn.pid, string)
  end

  defp execute_prepared_query(conn, string, args) do
    conn.adapter.execute_prepared_query(conn.pid, string, args)
  end
end
