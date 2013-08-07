Code.require_file "test_helper.exs", __DIR__


defmodule Atlas.Fixtures.Model do
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

  validates_format_of :name, with: %r/.*\s.*/
  validates_format_of :name, with: %r/.*\s.*/, message: "Your name must include first and last"

  validates_inclusion_of :name, in: ["jane", "bob"]
  validates_inclusion_of :name, in: ["jane", "bob"], message: "Select jane or bob"

  validates :lives_in_ohio

  def lives_in_ohio(record) do
    unless record.state == "OH" do
      {:state, "You must live in Ohio"}
    end
  end
end

defmodule Atlas.Fixtures.SimpleModel do
  use Atlas.Model
  field :name, :string
  validates_presence_of :name
  validates_length_of :name, greater_than: 2, less_than: 6
end

defmodule Atlas.ModelTest do
  use ExUnit.Case, async: true
  alias Atlas.Fixtures.Model
  alias Atlas.Fixtures.SimpleModel


  test "it adds validations to the module" do
    assert SimpleModel.__atlas__(:validations) == [
      {:length_of,:name,[greater_than: 2, less_than: 6]},
      {:presence_of,:name,[]}
    ]
  end

  test "#validate returns {:ok, record} when all validations return no errors" do
    assert SimpleModel.validate(SimpleModel.Record.new(name: "Chris")) ==
      { :ok, SimpleModel.Record.new(name: "Chris") }
  end

  test "#validate returns {:error, reasons} when validations return errors" do
    assert SimpleModel.validate(SimpleModel.Record.new(name: "Name Too Long")) == {
      :error, [name: "_ must be greater than 2 and less than 6 characters"]
    }
  end

  test "#valid? returns true if all validations pass" do
    assert SimpleModel.valid?(SimpleModel.Record.new(name: "Chris"))
  end

  test "valid? returns false is any validation fails" do
    refute SimpleModel.valid?(SimpleModel.Record.new(name: nil))
    refute SimpleModel.valid?(SimpleModel.Record.new(name: "A"))
    refute SimpleModel.valid?(SimpleModel.Record.new(name: "Name Too Long"))
  end

  test "#errors returns array of attribute, error message tuples" do
    assert Enum.first(SimpleModel.errors(SimpleModel.Record.new(name: "Name Too Long"))) == {
      :name, "_ must be greater than 2 and less than 6 characters"
    }
  end

  test "#full_error_messages returns array of binaries containing expanded errors" do
    assert Enum.first(SimpleModel.full_error_messages(SimpleModel.Record.new(name: "Name Too Long"))) ==
      "name must be greater than 2 and less than 6 characters"
  end

  test "#errors_on returns full error message for attribute" do
    assert SimpleModel.errors_on(SimpleModel.Record.new(name: "Name Too Long"), :name) ==
      ["name must be greater than 2 and less than 6 characters"]
  end


  test "#errors_on returns full error without attribute prefix if message starts with '_'" do
    assert Model.errors_on(Model.Record.new(name: "A"), :name)
           |> Enum.member?("Enter a reasonable name")
  end

  test "#errors_on returns full error with attribute prefix if message starts with '_'" do
    assert Model.errors_on(Model.Record.new(name: "A"), :name)
           |> Enum.member?("name doesn't appear to be avalid")
  end

  test "#validates_length_of with greather_than" do
    assert Model.errors_on(Model.Record.new(name: "A"), :name)
           |> Enum.member?("name must be greater than 2 characters")
    refute Model.errors_on(Model.Record.new(name: "Bob"), :name)
           |> Enum.member?("name must be greater than 2 characters")
  end

  test "#validates_length_of with greather_than_or_equal" do
    assert Model.errors_on(Model.Record.new(name: "A"), :name)
           |> Enum.member?("name must be greater than or equal to 3 characters")
    refute Model.errors_on(Model.Record.new(name: "Ted"), :name)
           |> Enum.member?("name must be greater than or equal to 3 characters")
  end

  test "#validates_length_of with greather_than and less_than" do
    assert Model.errors_on(Model.Record.new(name: "DJ DUBS TOO LONG"), :name)
           |> Enum.member?("name must be greater than 2 and less than 10 characters")
    refute Model.errors_on(Model.Record.new(name: "DJ DUBS"), :name)
           |> Enum.member?("name must be greater than 2 and less than 10 characters")
  end

  test "#validates_length_of with greather_than and less_than_or_equal" do
    assert Model.errors_on(Model.Record.new(name: "DJ DUBS TOO LONG"), :name)
           |> Enum.member?("name must be greater than 2 and less than or equal to 10 characters")
    assert Model.errors_on(Model.Record.new(name: "AB"), :name)
           |> Enum.member?("name must be greater than 2 and less than or equal to 10 characters")
    refute Model.errors_on(Model.Record.new(name: "DJ DUBS"), :name)
           |> Enum.member?("name must be greater than 2 and less than or equal to 10 characters")
  end

  test "#validates_presence_of" do
    assert Model.errors_on(Model.Record.new(name: nil), :name)
           |> Enum.member?("name must not be blank")
    refute Model.errors_on(Model.Record.new(name: "Max"), :name)
           |> Enum.member?("name must be greater than 2 and less than 10 characters")
  end

  test "#validates_numericality_of" do
    assert Model.errors_on(Model.Record.new(total: "bogus"), :total)
           |> Enum.member?("total must be a valid number")
    refute Model.errors_on(Model.Record.new(total: "1234"), :total)
           |> Enum.member?("total must be a valid number")
    refute Model.errors_on(Model.Record.new(total: "-12.34"), :total)
           |> Enum.member?("total must be a valid number")
    assert Model.errors_on(Model.Record.new(total: ""), :total)
           |> Enum.member?("total must be a valid number")
    refute Model.errors_on(Model.Record.new(total: 1234), :total)
           |> Enum.member?("total must be a valid number")
    refute Model.errors_on(Model.Record.new(total: -12.34), :total)
           |> Enum.member?("total must be a valid number")
    assert Model.errors_on(Model.Record.new(total: nil), :total)
           |> Enum.member?("total must be a valid number")
    assert Model.errors_on(Model.Record.new(total: []), :total)
           |> Enum.member?("total must be a valid number")
    assert Model.errors_on(Model.Record.new(total: true), :total)
           |> Enum.member?("total must be a valid number")
  end


  test "#validates_numericality_of with greather_than" do
    assert Model.errors_on(Model.Record.new(total: 2), :total)
           |> Enum.member?("total must be greater than 2")
    refute Model.errors_on(Model.Record.new(total: 3), :total)
           |> Enum.member?("total must be greater than 2")
  end

  test "#validates_numericality_of with greather_than_or_equal" do
    assert Model.errors_on(Model.Record.new(total: 2), :total)
           |> Enum.member?("total must be greater than or equal to 3")
    refute Model.errors_on(Model.Record.new(total: 10), :total)
           |> Enum.member?("total must be greater than or equal to 3")
  end

  test "#validates_numericality_of with greather_than and less_than" do
    assert Model.errors_on(Model.Record.new(total: 19), :total)
           |> Enum.member?("total must be greater than 20 and less than 100")
    assert Model.errors_on(Model.Record.new(total: 101), :total)
           |> Enum.member?("total must be greater than 20 and less than 100")
    refute Model.errors_on(Model.Record.new(total: 99), :total)
           |> Enum.member?("total must be greater than 20 and less than 100")
  end

  test "#validates_numericality_of with greather_than and less_than_or_equal" do
    assert Model.errors_on(Model.Record.new(total: 50), :total)
           |> Enum.member?("total must be greater than 50 and less than or equal to 80")
    assert Model.errors_on(Model.Record.new(total: 81), :total)
           |> Enum.member?("total must be greater than 50 and less than or equal to 80")
    refute Model.errors_on(Model.Record.new(total: 60), :total)
           |> Enum.member?("total must be greater than 50 and less than or equal to 80")
  end

  test "#validates_format_of" do
    assert Model.errors_on(Model.Record.new(name: "Chris"), :name)
           |> Enum.member?("name is not valid")
    refute Model.errors_on(Model.Record.new(name: "Chris McCord"), :name)
           |> Enum.member?("name is not valid")
  end

  test "#validates_format_of with custom error message" do
    assert Model.errors_on(Model.Record.new(name: "Chris"), :name)
           |> Enum.member?("Your name must include first and last")
    refute Model.errors_on(Model.Record.new(name: "Chris McCord"), :name)
           |> Enum.member?("Your name must include first and last")
  end

  test "#validates_inclusion_of" do
    assert Model.errors_on(Model.Record.new(name: "Chris"), :name)
           |> Enum.member?("name must be one of jane, bob")
    refute Model.errors_on(Model.Record.new(name: "jane"), :name)
           |> Enum.member?("name must be one of jane, bob")
  end

  test "#validates_inclusion_of with custom error message" do
    assert Model.errors_on(Model.Record.new(name: "Chris"), :name)
           |> Enum.member?("Select jane or bob")
    refute Model.errors_on(Model.Record.new(name: "jane"), :name)
           |> Enum.member?("Select jane or bob")
  end

  test "#validates allows adding custom validations" do
    assert Model.errors_on(Model.Record.new(state: "CA"), :state)
           |> Enum.member?("You must live in Ohio")
    refute Model.errors_on(Model.Record.new(state: "OH"), :state)
           |> Enum.member?("You must live in Ohio")
  end
end
