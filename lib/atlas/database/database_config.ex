defmodule Atlas.DatabaseConfig do
  def config(:dev) do
    [
      adapter: "",
      database: "",
      username: "",
      password: "",
      host: "",
      pool: 5
    ]
  end

  def config(:test) do
    [
      adapter: "",
      database: "",
      username: "",
      password: "",
      host: "",
      pool: 5
    ]
  end

  def config(:prod) do
    [
      adapter: "",
      database: "",
      username: "",
      password: "",
      host: "",
      pool: 5
    ]
  end
end