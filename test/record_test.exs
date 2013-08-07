Code.require_file "test_helper.exs", __DIR__

defmodule Atlas.RecordTest do
  use ExUnit.Case, async: true
  defrecord User, name: nil
  alias Atlas.Record

  setup do
    {:ok, record: User.new(name: "chris") }
  end

  test "#get returns record's value given attribute", meta do
    assert Record.get(meta[:record], :name) == "chris"
  end

  test "#to_list returns records attributes converted to keyword list", meta do
    assert Record.to_list(meta[:record]) == [name: "chris"]
  end
end
