Code.require_file "test_helper.exs", __DIR__

defmodule Atlas.ValidatorTest do
  use ExUnit.Case, async: true
  import Atlas.Validator

  test "#valid_number? returns true when given valid number as binary" do
    assert valid_number? "123"
    assert valid_number? "123.10"
    assert valid_number? "-123"
  end

  test "#valid_number? returns false when given invalid number as binary" do
    refute valid_number? "one hundred"
    refute valid_number? "x123.10"
    refute valid_number? ""
  end

  test "#valid_number? returns true when given any valid number" do
    assert valid_number? 1000
    assert valid_number? 1000.1
    assert valid_number? -1000.1
  end

  test "#valid_number? returns false when given non binary or number" do
    refute valid_number? []
    refute valid_number? [1, 2, 3]
    refute valid_number? {}
  end
end
