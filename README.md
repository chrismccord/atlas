# Atlas

Atlas is an Object Relational Mapper for Elixir. (Work in progress. Expect breaking changes)

## Current Features
- Postgres Adapter
- Validations
- Schema definitions
- Model query builder
- Auto-generated 'find_by' functions for each field definition

## Roadmap
- Persistence layer, create, update, destroy of records
- Extend query builder to support joins
- Add model relationships, ie `belongs_to`, `has_many`, `has_many through:`
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

  def admins do
    where(archived: false) |> where(is_site_admin: true)
  end
  
  def admin_with_email(email) do
    admins |> where(email: email)
  end
end

iex> admin = Repo.first User.admin_with_email("foo@bar.com")
User.Record[id: 5, email: "foo@bar.com", archived: false, is_site_admin: true...]
```

## Query Builder

### Examples
```elixir
iex> User.where(email: "user@example.com")
     |> User.where("state IS NOT NULL")
     |> User.order(update_at: :asc)
     |> Repo.all

[User.Record[id: 5, archived: true, is_site_admin: false...], User.Record[id: 5, archived: true, is_site_admin: false...]]

iex> user =  User.where(email: "user@example.com") |> Repo.first
User.Record[id: 5, archived: false, is_site_admin: false...]
iex> user.email
user@example.com

iex> User.where(archived: true)
     |> User.order(updated_at: :desc)
     |> Repo.first

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

    scope |> Repo.all
  end
end

iex> UserSearch.perform(is_site_admin: true, email: "user@example.com")
[User.Record[email: "user@example.com"]]
```

### Auto-generated finders

`with_[field name]` functions are automatically generated for all defined fields.
For example, a User module with a `field :email, :string` definition would include a `User.with_email` function
that returns the first record matching that field from the database.

## Validation Support
```
iex> user = User.Record.new(email: "invalid")
User.Record[id: nil, email: "invalid", is_site_admin: nil...

iex> User.validate user
{:error, User.Record[newsletter_updated_at: ...}, [email: "Email must be valid", email: "_ must be between 5 and 255 characters",
  email: "_ must not be blank"]}

iex> User.full_error_messages user
["Email must be valid","email must be between 5 and 255 characters","email must not be blank","id must be a valid number"]

```


## Repo Configuration
Create a `repo.ex` file in your project that uses Atlas.Repo with an adapter.
Your Repo simply needs to be provide config functions for `:dev`, `:test`, and `:prod` environments:

```elixir
defmodule Repo do
  use Atlas.Repo, adapter: Atlas.Adapters.Postgres

  def config(:dev) do
    [
      database: "",
      username: "",
      password: "",
      host: "",
      pool: 5,
      log_level: :debug
    ]
  end

  def config(:test) do
    [
      database: "",
      username: "",
      password: "",
      host: "",
      pool: 5,
      log_level: :debug
    ]
  end

  def config(:prod) do
    [
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
