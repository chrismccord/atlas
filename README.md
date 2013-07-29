# Atlas

Atlas is Object Relational Mapper for Elixir. (Work in progress. Expect breaking changes)

## Current Features
- Postgres Adapter
- Validations
- Schema definitions
- Model query builder
- Auto-generated 'find_by' functions for each field definition

## Roadmap
- Extend query builder to support joins
- Additional SQL adapters
- Schema migrations

## Example Usage:

```elixir
defmodule User do
  use Atlas.Model

  @table :users
  @primary_key :id
  
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
  
  def find_admin_by_email(email) do
    where(email: email, is_site_admin: true) |> first
  end
  
  def admin_count do
    where(archived: false)
    |> where(is_site_admin: true)
    |> count
  end
end
```

## Query Builder

### Examples
```elixir
iex> User.where(email: "user@example.com")
     |> User.where("state IS NOT NULL")
     |> User.order(update_at: :asc)
     |> User.to_records

[User.Record[id: 5, archived: true, is_site_admin: false...], User.Record[id: 5, archived: true, is_site_admin: false...]]

iex> user =  User.where(email: "user@example.com") |> User.first
User.Record[id: 5, archived: false, is_site_admin: false...]
iex> user.email
user@example.com

iex> User.where(archived: true) 
     |> User.order(updated_at: :desc) 
     |> User.first

User.Record[id: 5, archived: true, is_site_admin: false...]
```

#### Queries are composable
```elixir
defmodule UserSearch do
  import User
  
  def perform(options) do
    is_admin = Keyword.get options, :is_site_admin, false
    email    = Keyword.get options, :email, nil
    scope    = User.scoped
    
    scope = scope |> where(is_site_admin: is_admin)
    if email, do: scope = scope |> where(email: email) 
    
    scope |> to_records
  end
end

iex> UserSearch.perform(is_site_admin: true, email: "user@example.com")
[User.Record[email: "user@example.com"]]
```

### Auto-generated finders

`find_by_[field name]` functions are automatically generated for all defined fields. 
For example, a User module with a `field :email, :string` definition would include a `User.find_by_email` function 
that returns the first record matching that field from the database.

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
      pool: 5,
      log_level: :debug
    ]
  end

  def config(:test) do
    [
      adapter: PostgresAdapter,
      database: "",
      username: "",
      password: "",
      host: "localhost",
      pool: 5,
      log_level: :debug
    ]
  end

  def config(:prod) do
    [
      adapter: PostgresAdapter,
      database: "",
      username: "",
      password: "",
      host: "",
      pool: 5,
      log_level: :warn
    ]
  end
end
```
