defmodule Atlas do
  alias Atlas.Logger

  def start(_type, _config) do
    Logger.Supervisor.start_link(Logger.log_path)
    {:ok, self}
  end
end
