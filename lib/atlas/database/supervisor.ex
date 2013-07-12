defmodule Atlas.Database.Supervisor do
  use Supervisor.Behaviour

  alias Atlas.Database.ConfigInfo

  def start_link(config) do
    :supervisor.start_link(__MODULE__, config)
  end

  def init(config) do
    tree = [worker(Atlas.Database.Server, [config])]
    supervise tree, strategy: :one_for_all
  end
end