defmodule Atlas.Database.Server.ConfigInfo do
  defstruct adapter: nil,
            database: nil,
            username: nil,
            password: nil,
            host: nil,
            pool: 1
end
