# Atlas

Atlas is Object Relational Mapper for Elixir. (Work in progress. Expect breaking changes)

## Current Features
- Postgres Adapter
- Validations
- Schema definitions
- Raw string query to Record support

## Roadmap
- Full query to record DSL
- Additional SQL adapters
- Schema migrations

## Example Usage:

```elixir
defmodule User do
  use Atlas.Model

  field :id, :integer
  field :email, :string
  field :is_site_admin, :boolean
  field :archived, :boolean
  field :state, :string

  validates_numericality_of :id
  validates_presence_of :email
  validates_length_of :email, within: 5..255
  validates_format_of :email, with: %r/.*@.*/, message: "Email must be valid"
  validates :lives_in_ohio


  def lives_in_ohio(record) do
    unless record.state == "OH", do: {:state, "You must live in Ohio"}
  end
```


## Validation Support
```
iex> user = User.Record.new(email: "invalid")
User.Record[id: nil, email: "invalid", is_site_admin: nil...

iex> User.valid? user
false

iex> User.full_error_messages user
["Email must be valid","email must be between 5 and 255 characters","email must not be blank","id must be a valid number"]

```


## Database Configuration
Create a `database_config.ex` file in your project with an `Atlas.DatabaseConfig` module containing config methods for `:dev`, `:test`, and `:prod` environments:

```elixir
defmodule Atlas.DatabaseConfig do
  alias Atlas.Database.PostgresAdapter

  def config(:dev) do
    [
      adapter: PostgresAdapter,
      database: "",
      username: "",
      password: "",
      host: "localhost",
      pool: 5
    ]
  end

  def config(:test) do
    [
      adapter: PostgresAdapter,
      database: "",
      username: "",
      password: "",
      host: "localhost",
      pool: 5
    ]
  end

  def config(:prod) do
    [
      adapter: PostgresAdapter,
      database: "",
      username: "",
      password: "",
      host: "",
      pool: 5
    ]
  end
end
```
