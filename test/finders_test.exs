Code.require_file "test_helper.exs", __DIR__

defmodule Atlas.FindersTest do
  use ExUnit.Case
  use Atlas.PersistenceTestHelper

  setup_all do
    create_user(id: 1, name: "older", age: 6, state: "OH", active: true)
    create_user(id: 2, name: "younger", age: 5, state: "OH", active: true)
    :ok
  end

  defmodule Model do
    use Atlas.Model
    @table :models
    @primary_key :id

    field :id, :integer
    field :name, :string
    field :state, :string
    field :active, :boolean
    field :age, :integer
  end



  test "creates find_by_id function" do
    assert Model.find_by_id(1).id == 1
    refute Model.find_by_id(123)
  end

  test "creates find_by_name function" do
    assert Model.find_by_name("older").name == "older"
    refute Model.find_by_name("notexist")
  end

  test "creates find_by_state function" do
    assert Model.find_by_state("OH").state == "OH"
    refute Model.find_by_state("notexist")
  end

  test "creates find_by_active function" do
    assert Model.find_by_active(true).id == 1
    refute Model.find_by_active(false)
  end

  test "creates find_by_age function" do
    assert Model.find_by_age(5).name == "younger"
    refute Model.find_by_age(123)
  end
end
