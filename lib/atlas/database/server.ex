defmodule Atlas.Database.Server do
  use GenServer.Behaviour
  alias :pgsql, as: PG

  defrecord ConfigInfo, adapter: nil,
                        database: nil,
                        username: nil,
                        password: nil,
                        host: nil,
                        pool: 1

  def start_link(config_options) do
    :gen_server.start_link({:local, :db_server}, __MODULE__, [config_options], [])
  end

  def init([config_options]) do
    connections = connect_all(ConfigInfo.new(config_options))

    {:ok, {connections, Enum.first(connections)} }
  end

  def handle_call({:query, string}, _from, {connections, conn}) do
    {:reply, query(conn, string), {connections, next_conn(connections, conn)} }
  end

  defp connect_all(config) do
    Enum.map 1..(config.pool), fn pool ->
      {:ok, conn} = connnect(config)
      conn
    end
  end

  defp next_conn(connections, current_connection) do
    index = Enum.find_index(connections, &1 == current_connection)
    if index == Enum.count(connections) - 1 do
      Enum.first(connections)
    else
      Enum.at(connections, index + 1)
    end
  end

  defp connnect(config) do
    PG.connect(
      binary_to_list(config.host),
      binary_to_list(config.username),
      binary_to_list(config.password),
      database: binary_to_list(config.database)
    )
  end

  defp query(conn, string) do
    case PG.squery(conn, string) do
      {:ok, cols, rows} -> {:ok, nil, normalize_cols(cols), normalize_rows(rows)}
      {:ok, count}      -> {:ok, count, [], []}
      {:ok, count, cols, rows} -> {:ok, count, normalize_cols(cols), normalize_rows(rows)}
      {:error, error }  -> {:error, error }
    end
  end

  # Ex: {:column,"id",:int4,4,-1,0}
  defp normalize_cols(columns) do
    Enum.map columns, fn col -> binary_to_atom(elem(col, 1)) end
  end

  defp normalize_rows(rows) do
    Enum.map(rows, tuple_to_list(&1))
  end
end