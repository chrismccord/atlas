defmodule Atlas do
  alias Atlas.Database
  alias Atlas.DatabaseConfig
  alias Atlas.Logger


  def start(_type, _config) do
    # Database.Supervisor.start_link(database_config)
    Logger.Supervisor.start_link(Logger.log_path)

    {:ok, self}
  end

  def database_config do
    DatabaseConfig.config(Mix.env)
  end
end
