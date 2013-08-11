defmodule Atlas.Model do

  defmacro __using__(_options) do
    quote do
      use Atlas.Schema
      use Atlas.QueryBuilder
      use Atlas.Validator
      use Atlas.Finders
      use Atlas.Persistence

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
  end
end


defmodule User do
  use Atlas.Model

  @table :users
  @primary_key :id

  field :id, :integer
  field :login, :string
  field :email, :string
  field :crypted_password, :string
  field :salt, :string
  field :remember_token, :boolean
  field :password_reset_token, :string
  field :roles, :string
  field :remember_token_expires_at, :datetime
  field :password_reset_token_issued_at, :datetime
  field :newsletter, :boolean
  field :created_at, :datetime
  field :updated_at, :datetime
  field :is_site_admin, :boolean
  field :archived, :boolean
  field :newsletter_updated_at, :datetime

  validates_presence_of :email
  validates_length_of :email, within: 5..255
  validates_format_of :email, with: %r/.*@.*/, message: "Email must be valid"
  # validates_inclusion_of :age, in: [1, 2, 3]

  # validates :lives_in_ohio


  # def lives_in_ohio(record) do
  #   unless record.city == "Fairborn", do: {:city, "must be in Ohio"}
  # end

  def is_archived?(user) do
    user.archived
  end
end
