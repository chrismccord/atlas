Code.require_file "../test_helper.exs", __DIR__

defmodule Atlas.CountTest do
  use ExUnit.Case, async: true
  import Atlas.Count

  test "it implements count for List" do
    assert count([1, 2, 3]) == 3
    assert count([]) == 0
  end

  test "it implements count for BitString" do
    assert count("") == 0
    assert count("test") == 4
  end

  test "it implements count for Atom" do
    assert count(nil) == 0
    assert count(:atom) == 4
  end
end
