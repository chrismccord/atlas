Code.require_file "test_helper.exs", __DIR__

defmodule Atlas.Fixtures.User do
  use Atlas.Model

  field :name, :string
  field :total, :float
  field :state, :string

  validates_presence_of :name
  validates_length_of :name, greater_than: 2, less_than: 6
  validates_length_of :name, within: 2..10, message: "Enter a reasonable name"
  validates_length_of :name, within: 2..10, message: "_ doesn't appear to be avalid"
  validates_length_of :name, greater_than: 2
  validates_length_of :name, greater_than_or_equal: 3
  validates_length_of :name, greater_than: 2, less_than: 10
  validates_length_of :name, greater_than: 2, less_than_or_equal: 10

  validates_numericality_of :total
  validates_numericality_of :total, greater_than: 2
  validates_numericality_of :total, greater_than_or_equal: 3
  validates_numericality_of :total, greater_than: 20, less_than: 100
  validates_numericality_of :total, greater_than: 50, less_than_or_equal: 80

  validates_format_of :name, with: ~r/.*\s.*/
  validates_format_of :name, with: ~r/.*\s.*/, message: "Your name must include first and last"

  validates_inclusion_of :name, in: ["jane", "bob"]
  validates_inclusion_of :name, in: ["jane", "bob"], message: "Select jane or bob"

  validates :lives_in_ohio

  def lives_in_ohio(record) do
    unless record.state == "OH" do
      {:state, "You must live in Ohio"}
    end
  end
end

defmodule Atlas.Fixtures.SimpleUser do
  use Atlas.Model
  field :name, :string
  validates_presence_of :name
  validates_length_of :name, greater_than: 2, less_than: 6
end

defmodule Atlas.UserTest do
  use ExUnit.Case, async: true
  alias Atlas.Fixtures.User
  alias Atlas.Fixtures.SimpleUser


  test "it adds validations to the module" do
    assert SimpleUser.__atlas__(:validations) == [
      {:length_of,:name,[greater_than: 2, less_than: 6]},
      {:presence_of,:name,[]}
    ]
  end

  test "#validate returns {:ok, record} when all validations return no errors" do
    assert SimpleUser.validate(SimpleUser.Record.new(name: "Chris")) ==
      { :ok, SimpleUser.Record.new(name: "Chris") }
  end

  test "#validate returns {:error, reasons} when validations return errors" do
    record = SimpleUser.Record.new(name: "Name Too Long")
    assert SimpleUser.validate(record) == {
      :error, record, [name: "_ must be greater than 2 and less than 6 characters"]
    }
  end

  test "#validate returns {:ok, record} if all validations pass" do
    {:ok, user} = SimpleUser.validate(SimpleUser.Record.new(name: "Chris"))
    assert user.name == "Chris"
  end

  test "validate returns {:ok, record, errors} is any validation fails" do
    {:error, _, errors} = SimpleUser.validate(SimpleUser.Record.new(name: nil))
    assert errors == SimpleUser.errors(SimpleUser.Record.new(name: nil))

    {:error, _, errors} = SimpleUser.validate(SimpleUser.Record.new(name: "A"))
    assert errors == SimpleUser.errors(SimpleUser.Record.new(name: "A"))

    {:error, _, errors} = SimpleUser.validate(SimpleUser.Record.new(name: "Name Too Long"))
    assert errors == SimpleUser.errors(SimpleUser.Record.new(name: "Name Too Long"))
  end

  test "#errors returns array of attribute, error message tuples" do
    assert List.first(SimpleUser.errors(SimpleUser.Record.new(name: "Name Too Long"))) == {
      :name, "_ must be greater than 2 and less than 6 characters"
    }
  end

  test "#full_error_messages returns array of binaries containing expanded errors" do
    assert List.first(SimpleUser.full_error_messages(SimpleUser.Record.new(name: "Name Too Long"))) ==
      "name must be greater than 2 and less than 6 characters"
  end

  test "#errors_on returns full error message for attribute" do
    assert SimpleUser.errors_on(SimpleUser.Record.new(name: "Name Too Long"), :name) ==
      ["name must be greater than 2 and less than 6 characters"]
  end


  test "#errors_on returns full error without attribute prefix if message starts with '_'" do
    assert User.errors_on(User.Record.new(name: "A"), :name)
           |> Enum.member?("Enter a reasonable name")
  end

  test "#errors_on returns full error with attribute prefix if message starts with '_'" do
    assert User.errors_on(User.Record.new(name: "A"), :name)
           |> Enum.member?("name doesn't appear to be avalid")
  end

  test "#validates_length_of with greather_than" do
    assert User.errors_on(User.Record.new(name: "A"), :name)
           |> Enum.member?("name must be greater than 2 characters")
    refute User.errors_on(User.Record.new(name: "Bob"), :name)
           |> Enum.member?("name must be greater than 2 characters")
  end

  test "#validates_length_of with greather_than_or_equal" do
    assert User.errors_on(User.Record.new(name: "A"), :name)
           |> Enum.member?("name must be greater than or equal to 3 characters")
    refute User.errors_on(User.Record.new(name: "Ted"), :name)
           |> Enum.member?("name must be greater than or equal to 3 characters")
  end

  test "#validates_length_of with greather_than and less_than" do
    assert User.errors_on(User.Record.new(name: "DJ DUBS TOO LONG"), :name)
           |> Enum.member?("name must be greater than 2 and less than 10 characters")
    refute User.errors_on(User.Record.new(name: "DJ DUBS"), :name)
           |> Enum.member?("name must be greater than 2 and less than 10 characters")
  end

  test "#validates_length_of with greather_than and less_than_or_equal" do
    assert User.errors_on(User.Record.new(name: "DJ DUBS TOO LONG"), :name)
           |> Enum.member?("name must be greater than 2 and less than or equal to 10 characters")
    assert User.errors_on(User.Record.new(name: "AB"), :name)
           |> Enum.member?("name must be greater than 2 and less than or equal to 10 characters")
    refute User.errors_on(User.Record.new(name: "DJ DUBS"), :name)
           |> Enum.member?("name must be greater than 2 and less than or equal to 10 characters")
  end

  test "#validates_presence_of" do
    assert User.errors_on(User.Record.new(name: nil), :name)
           |> Enum.member?("name must not be blank")
    refute User.errors_on(User.Record.new(name: "Max"), :name)
           |> Enum.member?("name must be greater than 2 and less than 10 characters")
  end

  test "#validates_numericality_of" do
    assert User.errors_on(User.Record.new(total: "bogus"), :total)
           |> Enum.member?("total must be a valid number")
    refute User.errors_on(User.Record.new(total: "1234"), :total)
           |> Enum.member?("total must be a valid number")
    refute User.errors_on(User.Record.new(total: "-12.34"), :total)
           |> Enum.member?("total must be a valid number")
    assert User.errors_on(User.Record.new(total: ""), :total)
           |> Enum.member?("total must be a valid number")
    refute User.errors_on(User.Record.new(total: 1234), :total)
           |> Enum.member?("total must be a valid number")
    refute User.errors_on(User.Record.new(total: -12.34), :total)
           |> Enum.member?("total must be a valid number")
    assert User.errors_on(User.Record.new(total: nil), :total)
           |> Enum.member?("total must be a valid number")
    assert User.errors_on(User.Record.new(total: []), :total)
           |> Enum.member?("total must be a valid number")
    assert User.errors_on(User.Record.new(total: true), :total)
           |> Enum.member?("total must be a valid number")
  end


  test "#validates_numericality_of with greather_than" do
    assert User.errors_on(User.Record.new(total: 2), :total)
           |> Enum.member?("total must be greater than 2")
    refute User.errors_on(User.Record.new(total: 3), :total)
           |> Enum.member?("total must be greater than 2")
  end

  test "#validates_numericality_of with greather_than_or_equal" do
    assert User.errors_on(User.Record.new(total: 2), :total)
           |> Enum.member?("total must be greater than or equal to 3")
    refute User.errors_on(User.Record.new(total: 10), :total)
           |> Enum.member?("total must be greater than or equal to 3")
  end

  test "#validates_numericality_of with greather_than and less_than" do
    assert User.errors_on(User.Record.new(total: 19), :total)
           |> Enum.member?("total must be greater than 20 and less than 100")
    assert User.errors_on(User.Record.new(total: 101), :total)
           |> Enum.member?("total must be greater than 20 and less than 100")
    refute User.errors_on(User.Record.new(total: 99), :total)
           |> Enum.member?("total must be greater than 20 and less than 100")
  end

  test "#validates_numericality_of with greather_than and less_than_or_equal" do
    assert User.errors_on(User.Record.new(total: 50), :total)
           |> Enum.member?("total must be greater than 50 and less than or equal to 80")
    assert User.errors_on(User.Record.new(total: 81), :total)
           |> Enum.member?("total must be greater than 50 and less than or equal to 80")
    refute User.errors_on(User.Record.new(total: 60), :total)
           |> Enum.member?("total must be greater than 50 and less than or equal to 80")
  end

  test "#validates_format_of" do
    assert User.errors_on(User.Record.new(name: "Chris"), :name)
           |> Enum.member?("name is not valid")
    refute User.errors_on(User.Record.new(name: "Chris McCord"), :name)
           |> Enum.member?("name is not valid")
  end

  test "#validates_format_of with custom error message" do
    assert User.errors_on(User.Record.new(name: "Chris"), :name)
           |> Enum.member?("Your name must include first and last")
    refute User.errors_on(User.Record.new(name: "Chris McCord"), :name)
           |> Enum.member?("Your name must include first and last")
  end

  test "#validates_inclusion_of" do
    assert User.errors_on(User.Record.new(name: "Chris"), :name)
           |> Enum.member?("name must be one of jane, bob")
    refute User.errors_on(User.Record.new(name: "jane"), :name)
           |> Enum.member?("name must be one of jane, bob")
  end

  test "#validates_inclusion_of with custom error message" do
    assert User.errors_on(User.Record.new(name: "Chris"), :name)
           |> Enum.member?("Select jane or bob")
    refute User.errors_on(User.Record.new(name: "jane"), :name)
           |> Enum.member?("Select jane or bob")
  end

  test "#validates allows adding custom validations" do
    assert User.errors_on(User.Record.new(state: "CA"), :state)
           |> Enum.member?("You must live in Ohio")
    refute User.errors_on(User.Record.new(state: "OH"), :state)
           |> Enum.member?("You must live in Ohio")
  end
end
