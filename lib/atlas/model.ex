defmodule Atlas.Model do

  defmacro __using__(_options) do
    quote do
      use Atlas.Schema
      use Atlas.Query.Builder
      use Atlas.Validator
      use Atlas.Finders
      use Atlas.Accessors
    end
  end
end

# Examples
# defmodule Order do
#   use Atlas.Model

#   @table :orders
#   @primary_key :id

#   field :id, :integer
#   field :user_id, :integer
#   field :merchandise_total, :float

#   belongs_to :user, foreign_key: :user_id, model: User
# end

# defmodule User do
#   use Atlas.Model

#   @table :users
#   @primary_key :id

#   field :id, :integer
#   field :login, :string
#   field :email, :string
#   field :crypted_password, :string
#   field :salt, :string
#   field :remember_token, :boolean
#   field :password_reset_token, :string
#   field :roles, :string
#   field :remember_token_expires_at, :datetime
#   field :password_reset_token_issued_at, :datetime
#   field :newsletter, :boolean
#   field :created_at, :datetime
#   field :updated_at, :datetime
#   field :is_site_admin, :boolean
#   field :archived, :boolean
#   field :newsletter_updated_at, :datetime

#   has_many :orders, foreign_key: :user_id, model: Order

#   validates_presence_of :email
#   validates_length_of :email, within: 5..255
#   validates_format_of :email, with: %r/.*@.*/, message: "Email must be valid"
#   # validates_inclusion_of :age, in: [1, 2, 3]

#   # validates :lives_in_ohio


#   # def lives_in_ohio(record) do
#   #   unless record.city == "Fairborn", do: {:city, "must be in Ohio"}
#   # end


#   def assign(record, :email, value) do
#     email = String.downcase(value)
#     record.update(email: email, login: email)
#   end

#   def email(record) do
#     record.email |> String.upcase
#   end

#   def is_archived?(user) do
#     user.archived
#   end
# end
