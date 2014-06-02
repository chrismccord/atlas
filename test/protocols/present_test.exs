Code.require_file "../test_helper.exs", __DIR__

defmodule Atlas.PresentTest do
  use ExUnit.Case, async: true
  import Atlas.Present

  test "it implements present? for Number" do
    assert present?(1)
    assert present?(0)
    assert present?(-10)
  end

  test "it implements present? for List" do
    refute present?([])
    assert present?([1, 2, 3])
  end

  test "it implements present? for Atom" do
    refute present?(false)
    refute present?(nil)
    assert present?(:present)
  end

  test "it implements present? for BitString" do
    assert present?("here")
    refute present?("")
  end

  test "it implements present? for Map" do
    refute present?(%{})
    assert present?(%{foo: :bar})
  end
end
