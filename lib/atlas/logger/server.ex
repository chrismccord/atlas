defmodule Atlas.Logger.Server do
  use GenServer.Behaviour

  def start_link(log_path) do
    :gen_server.start_link({:local, :logger_server}, __MODULE__, [log_path], [])
  end

  def init([log_path]) do
    case File.open(log_path, [:append]) do
      {:ok, pid} -> {:ok, pid}
      {:error, reason} -> IO.puts "!    Unable to open log file: #{reason}"
    end
  end

  def handle_call({:write, string}, _from, pid) do
    {:reply, IO.puts(pid, string), pid}
  end
end