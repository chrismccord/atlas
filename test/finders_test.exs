Code.require_file "test_helper.exs", __DIR__

defmodule Atlas.FindersTest do
  use ExUnit.Case
  use Atlas.PersistenceTestHelper

  setup_all do
    create_user(id: 1, name: "older", age: 6, state: "OH", active: true)
    create_user(id: 2, name: "younger", age: 5, state: "OH", active: true)
    :ok
  end


  test "creates with_id function" do
    assert Repo.first(Model.with_id(1)).id == 1
    refute Repo.first(Model.with_id(123))
  end

  test "creates with_name function" do
    assert Repo.first(Model.with_name("older")).name == "older"
    refute Repo.first(Model.with_name("notexist"))
  end

  test "creates with_state function" do
    assert Repo.first(Model.with_state("OH")).state == "OH"
    refute Repo.first(Model.with_state("notexist"))
  end

  test "creates with_active function" do
    assert Repo.first(Model.with_active(true)).id == 1
    refute Repo.first(Model.with_active(false))
  end

  test "creates with_age function" do
    assert Repo.first(Model.with_age(5)).name == "younger"
    refute Repo.first(Model.with_age(123))
  end
end
