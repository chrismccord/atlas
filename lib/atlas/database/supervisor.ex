defmodule Atlas.Database.Supervisor do
  use Supervisor.Behaviour

  def stop(repo) do
    Process.exit Process.whereis(name(repo)), :shutdown
  end

  def start_link(repo) do
    :supervisor.start_link({:local, name(repo)}, __MODULE__, repo)
  end

  def init(repo) do
    tree = [worker(Atlas.Database.Server, [repo])]
    supervise tree, strategy: :one_for_all
  end

  defp name(repo) do
    :"supervisor_#{repo.server_name}"
  end
end
