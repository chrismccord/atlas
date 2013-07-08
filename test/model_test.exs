Code.require_file "test_helper.exs", __DIR__

defrecord Atlas.ModelTest.TestRecord, name: nil, total: nil, state: nil
defmodule Atlas.ModelTest.TestModule do
  use Atlas.Model

  validates_presence_of :name
  validates_length_of :name, greater_than: 2, less_than: 6
end

defmodule Atlas.ModelTest.Fixtures do
  alias Atlas.ModelTest.TestRecord

  def valid_record,   do: TestRecord.new(name: "Chris")
  def invalid_record, do: TestRecord.new(name: "Name Too Long")
end

defmodule Atlas.ModelTest do
  use ExUnit.Case, async: true
  import Atlas.ModelTest.Fixtures
  alias Atlas.ModelTest.TestModule
  alias Atlas.ModelTest.TestRecord


  test "it adds validations to the module" do
    assert TestModule.validations == [
      {:length_of,:name,[greater_than: 2, less_than: 6]},
      {:presence_of,:name,[]}
    ]
  end

  test "#validate returns {:ok, record} when all validations return no errors" do
    assert TestModule.validate(valid_record) == { :ok, valid_record }
  end

  test "#validate returns {:error, reasons} when validations return errors" do
    assert TestModule.validate(invalid_record) == { 
      :error, [name: "_ must be greater than 2 and less than 6 characters"] 
    }
  end

  test "#valid? returns true when validations return no errors" do
    assert TestModule.valid?(valid_record)
  end

  test "#valid? returns false when validations return any errors" do
    refute TestModule.valid?(invalid_record)
  end

  test "#errors returns array of attribute, error message tuples" do
    assert Enum.first(TestModule.errors(invalid_record)) == {
      :name, "_ must be greater than 2 and less than 6 characters"
    }
  end

  test "#full_error_messages returns array of binaries containing expanded errors" do
    assert Enum.first(TestModule.full_error_messages(invalid_record)) == 
      "name must be greater than 2 and less than 6 characters"
  end

  test "#errors_on returns full error message for attribute" do
    assert TestModule.errors_on(invalid_record, :name) ==
      "name must be greater than 2 and less than 6 characters"
  end

  test "#errors_on returns full error without attribute prefix if message starts with '_'" do
    defmodule ErrorsOnCustom do
      use Atlas.Model
      validates_length_of :name, within: 2..10, message: "Enter a reasonable name"
    end
    assert ErrorsOnCustom.errors_on(TestRecord.new(name: "A"), :name) ==
      "Enter a reasonable name"
  end

  test "#errors_on returns full error with attribute prefix if message starts with '_'" do
    defmodule ErrorsOnCustom2 do
      use Atlas.Model
      validates_length_of :name, within: 2..10, message: "_ doesn't appear to be avalid"
    end
    assert ErrorsOnCustom2.errors_on(TestRecord.new(name: "A"), :name) ==
      "name doesn't appear to be avalid"
  end

  test "#validates_length_of with greather_than" do
    defmodule LengthOf do
      use Atlas.Model
      validates_length_of :name, greater_than: 2
    end
    errors = LengthOf.full_error_messages(TestRecord.new name: "DJ")

    assert Enum.member? errors, "name must be greater than 2 characters"
    assert LengthOf.valid?(TestRecord.new name: "DJ DUBS")
  end

  test "#validates_length_of with greather_than_or_equal" do
    defmodule LengthOf1 do
      use Atlas.Model
      validates_length_of :name, greater_than_or_equal: 3
    end
    errors = LengthOf1.full_error_messages(TestRecord.new name: "DJ")

    assert Enum.member? errors, "name must be greater than or equal to 3 characters"
    assert LengthOf1.valid?(TestRecord.new name: "DJ DUBS")
  end

  test "#validates_length_of with greather_than and less_than" do
    defmodule LengthOf2 do
      use Atlas.Model
      validates_length_of :name, greater_than: 2, less_than: 10
    end
    errors = LengthOf2.full_error_messages(TestRecord.new name: "DJ")

    assert Enum.member? errors, "name must be greater than 2 and less than 10 characters"
    assert LengthOf2.valid?(TestRecord.new name: "DJ DUBS")
    refute LengthOf2.valid?(TestRecord.new name: "DJ DUBS TOO LONG")
  end

  test "#validates_length_of with greather_than and less_than_or_equal" do
    defmodule LengthOf3 do
      use Atlas.Model
      validates_length_of :name, greater_than: 2, less_than_or_equal: 10
    end
    errors = LengthOf3.full_error_messages(TestRecord.new name: "DJ")

    assert Enum.member? errors, "name must be greater than 2 and less than or equal to 10 characters"
    assert LengthOf3.valid?(TestRecord.new name: "DJ DUBS")
    refute LengthOf3.valid?(TestRecord.new name: "DJ DUBS TOO LONG")
  end

  test "#validates_presence_of" do
    defmodule PresenceOf do
      use Atlas.Model
      validates_presence_of :name
    end
    errors = PresenceOf.full_error_messages(TestRecord.new name: nil)

    assert Enum.first(errors) == "name must not be blank"
    assert PresenceOf.valid?(TestRecord.new name: "Chris")
    refute PresenceOf.valid?(TestRecord.new name: nil)
  end

  test "#validates_numericality_of" do
    defmodule NumericalityOf do
      use Atlas.Model
      validates_numericality_of :total
    end
    errors = NumericalityOf.full_error_messages(TestRecord.new total: "bogus")

    assert Enum.first(errors) == "total must be a valid number"
    assert NumericalityOf.valid?(TestRecord.new total: "1234")
    assert NumericalityOf.valid?(TestRecord.new total: "-12.34")
    refute NumericalityOf.valid?(TestRecord.new total: "")
    assert NumericalityOf.valid?(TestRecord.new total: 1234)
    assert NumericalityOf.valid?(TestRecord.new total: -12.34)
    refute NumericalityOf.valid?(TestRecord.new total: nil)
    refute NumericalityOf.valid?(TestRecord.new total: [])
    refute NumericalityOf.valid?(TestRecord.new total: true)
  end

  test "#validates_format_of" do
    defmodule FormatOf do
      use Atlas.Model
      validates_format_of :name, with: %r/.*\s.*/
    end

    errors = FormatOf.full_error_messages(TestRecord.new name: "Chris")
    assert Enum.first(errors) == "name is not valid"
    assert FormatOf.valid?(TestRecord.new name: "Chris McCord")
  end

  test "#validates_format_of with custom error message" do
    defmodule FormatOf2 do
      use Atlas.Model
      validates_format_of :name, with: %r/.*\s.*/, message: "Your name must include first and last"
    end

    errors = FormatOf2.full_error_messages(TestRecord.new name: "Chris")
    assert Enum.first(errors) == "Your name must include first and last"
    assert FormatOf2.valid?(TestRecord.new name: "Chris McCord")
  end

  test "#validates allows adding custom validations" do
    defmodule CustomValidation do
      use Atlas.Model
      validates :lives_in_ohio
      def lives_in_ohio(record) do
        unless record.state == "OH" do
          {:state, "You must live in Ohio"}
        end
      end
    end
    errors = CustomValidation.full_error_messages(TestRecord.new state: "CA")

    assert Enum.first(errors) == "You must live in Ohio"
    refute CustomValidation.valid? TestRecord.new state: "CA"
    assert CustomValidation.valid? TestRecord.new state: "OH"
  end
end
