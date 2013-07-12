defmodule Atlas do
  alias Atlas.Database
  alias Atlas.DatabaseConfig

  def start(_type, _config) do
    Database.Supervisor.start_link(database_config)

    {:ok, self}
  end

  def database_config do
    DatabaseConfig.config(Mix.env)
  end
end
