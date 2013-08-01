defmodule Atlas.Logger.Supervisor do
  use Supervisor.Behaviour

  def start_link(log_path) do
    :supervisor.start_link(__MODULE__, log_path)
  end

  def init(log_path) do
    tree = [worker(Atlas.Logger.Server, [log_path])]
    supervise tree, strategy: :one_for_all
  end
end