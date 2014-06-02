defmodule Atlas.Logger.Server do
  use GenServer

  def start_link(log_path) do
    GenServer.start_link(__MODULE__, [log_path], name: :logger_server)
  end

  def init([log_path]) do
    case File.open(log_path, [:append]) do
      {:ok, pid} -> {:ok, pid}
      {:error, reason} -> IO.puts "Unable to open log file: #{reason} at #{log_path}"
    end
  end

  def handle_call({:write, string}, _from, pid) do
    {:reply, IO.puts(pid, string), pid}
  end
end
