Code.require_file "../test_helper.exs", __DIR__

defmodule Atlas.PersistenceTest do
  use ExUnit.Case
  use Atlas.PersistenceTestHelper
  alias Atlas.Database.Client

  setup_all do
    create_user(name: "older", age: 6, state: "OH", active: true)
    create_user(name: "younger", age: 5, state: "OH", active: true)
    :ok
  end

  test "persisted? returns true if record has primary key" do
    assert Model.persisted?(Model.Record.new(id: 1))
  end
  test "persisted? returns false if record has no primary key" do
    refute Model.persisted?(Model.Record.new(id: nil))
  end

  test "#save updates the records attributes to the database with valid model" do
    record = Model.find_by_name("older")
    assert record.age == 6
    assert Model.valid?(record)
    {:ok, record} = Model.update(record, age: 18)
    assert record.age == 18
    assert Model.find_by_name("older").age == 18
  end
  test "#save does not update database and returns error list when invalid" do
    record = Model.find_by_name("older")

    assert Model.valid?(record)
    {:error, record_with_failed_attrs, errors} = Model.update(record, age: 0)
    refute Model.valid?(record_with_failed_attrs)
    assert record_with_failed_attrs.age == 0
    assert :age in Keyword.keys(errors)
    assert Model.find_by_name("older").age == 6
  end

  test "#create with keyword list inserts record attributes into the database" do
    refute Model.find_by_name("José")
    {:ok, _user} = Model.create(name: "José", age: 30)
    assert Model.find_by_name("José")
  end
  test "#create with record inserts record attributes into the database" do
    refute Model.find_by_name("Joe")
    {:ok, _user} = Model.create(Model.Record.new(name: "Joe", age: 30))
    assert Model.find_by_name("Joe")
  end

  test "#destroy deletes the record from the database" do
    {:ok, user} = Model.create(name: "Bob", age: 30)
    assert Model.find_by_name("Bob")
    {:ok, user} = Model.destroy(user)
    refute Model.find_by_name("Bob")
  end
  test "#destroy sets the record primary key to nil" do
    {:ok, user} = Model.create(name: "Bob", age: 30)
    assert user.id != nil
    {:ok, user} = Model.destroy(user)
    assert user.id == nil
    refute Model.persisted?(user)
  end

  test "#destroy_all with relation deletes all matching records from database" do
    Enum.each 1..10, fn i ->
      {:ok, user} = Model.create(name: "Bob#{i}", age: i + 100)
    end
    scope = Model.where("age > ?", 100)
    count_before_destroy = scope |> Model.count
    assert Model.destroy_all(scope)
    count_after_destroy = scope |> Model.count
    assert count_before_destroy != count_after_destroy
    assert (count_before_destroy - count_after_destroy) == 10
    assert Model.count(scope) == 0
  end
  # test "#destroy_all with list of records deletes all records from database" do
  #   Enum.each 1..10, fn i ->
  #     {:ok, user} = Model.create(name: "Bob#{i}", age: i + 100)
  #   end
  #   scope = Model.where("age > ?", 100)
  #   count_before_destroy = scope |> Model.count
  #   assert Model.destroy_all(scope)
  #   count_after_destroy = scope |> Model.count
  #   assert count_before_destroy != count_after_destroy
  #   assert (count_before_destroy - count_after_destroy) == 10
  #   assert Model.count(scope) == 0
  # end
end
