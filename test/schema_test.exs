Code.require_file "test_helper.exs", __DIR__


defmodule Atlas.SchemaTest do
  use ExUnit.Case, async: true
  alias Atlas.Schema

  defmodule User do
    use Atlas.Model

    field :id, :integer
    field :age, :integer, default: 18
    field :total, :float
    field :active, :boolean
  end

  test "macro #field appends field definition to `fields` attribute" do
    assert User.__atlas__(:fields) == [{:active, :boolean, [], nil},
                                       {:total, :float, [], nil},
                                       {:age, :integer, [default: 18], nil},
                                       {:id, :integer, [], nil}]
  end

  test "macro #field defines __MODULE__.Record with defined fields" do
    assert User.Record.new.age == 18
    assert User.Record.new.id == nil
  end

  test "#fields_to_kwlist converts @fields attribute to keyword list with default values" do
    fields = [{:id, :integer, [], nil}, {:active, :boolean, [default: true], nil}]
    assert Schema.fields_to_kwlist(fields) == [id: nil, active: true]
    assert User.Record.new == User.Record[id: nil, age: 18]
  end

  test "#default_for_field returns default value" do
    assert Schema.default_for_field({:age, :integer, [default: 18], nil}) == 18
    assert User.Record.new.age == 18
  end

  test "#default_for_field returns nil when no default value given" do
    assert Schema.default_for_field({:age, :integer, [], nil}) == nil
  end

  test ":integer fields" do
    assert User.raw_kwlist_to_field_types([id: "123"]) == [id: 123]
  end

  test ":string fields" do
    assert User.raw_kwlist_to_field_types([id: "123"]) == [id: 123]
  end

  test ":boolean fields" do
    assert User.raw_kwlist_to_field_types([active: "true"]) == [active: true]
  end

  test ":float fields" do
    assert User.raw_kwlist_to_field_types([total: "123"]) == [total: 123.0]
    assert User.raw_kwlist_to_field_types([total: "123.10"]) == [total: 123.10]
  end
end
