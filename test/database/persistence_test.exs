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
    assert Repo.persisted?(Model.Record.new(id: 1), Model)
  end
  test "persisted? returns false if record has no primary key" do
    refute Repo.persisted?(Model.Record.new(id: nil), Model)
  end

  test "#update updates the records attributes to the database with valid model" do
    record = Repo.first(Model.where(name: "older"))
    assert record.age == 6
    {:ok, _} = Model.validate(record)
    {:ok, record} = Repo.update(Model, record, age: 18)
    assert record.age == 18
    assert Repo.first(Model.where(name: "older")).age == 18
  end
  test "#update does not update database and returns error list when invalid" do
    record = Repo.first(Model.where(name: "older"))

    {:ok, _} = Model.validate(record)
    {:error, record_with_failed_attrs, errors} = Repo.update(Model, record, age: 0)
    {:error, _, _} = Model.validate(record_with_failed_attrs)
    assert record_with_failed_attrs.age == 0
    assert :age in Keyword.keys(errors)
    assert Repo.first(Model.where(name: "older")).age == 6
  end

  test "#create with keyword list inserts record attributes into the database" do
    refute Repo.first(Model.where(name: "José"))
    {:ok, _user} = Repo.create(Model, name: "José", age: 30)
    assert Repo.first(Model.where(name: "José"))
  end
  test "#create with record inserts record attributes into the database" do
    refute Repo.first(Model.where(name: "Joe"))
    {:ok, _user} = Repo.create(Model, Model.Record.new(name: "Joe", age: 30))
    assert Repo.first(Model.where(name: "Joe"))
  end

  test "#destroy deletes the record from the database" do
    {:ok, user} = Repo.create(Model, name: "Bob", age: 30)
    assert Repo.first(Model.where(name: "Bob"))
    {:ok, _} = Repo.destroy(Model, user)
    refute Repo.first(Model.where(name: "Bob"))
  end
  test "#destroy sets the record primary key to nil" do
    {:ok, user} = Repo.create(Model, name: "Bob", age: 30)
    assert user.id != nil
    {:ok, user} = Repo.destroy(Model, user)
    assert user.id == nil
    refute Repo.persisted?(user, Model)
  end

  test "#destroy_all with relation deletes all matching records from database" do
    Enum.each 1..10, fn i ->
      {:ok, _} = Repo.create(Model, name: "Bob#{i}", age: i + 100)
    end
    scope = Model.where("age > ?", 100)
    count_before_destroy = scope |> Repo.count
    assert Repo.destroy_all(scope)
    count_after_destroy = scope |> Repo.count
    assert count_before_destroy != count_after_destroy
    assert (count_before_destroy - count_after_destroy) == 10
    assert Repo.count(scope) == 0
  end

  test "#destroy_all with list of records deletes all records from database" do
    Enum.each 1..10, fn i ->
      {:ok, _user} = Repo.create(Model, name: "Bob#{i}", age: i + 100)
    end
    scope = Model.where("age > ?", 100)
    records = Repo.all(scope)
    count_before_destroy = scope |> Repo.count

    assert Repo.destroy_all(records, Model)
    count_after_destroy = scope |> Repo.count
    assert count_before_destroy != count_after_destroy
    assert (count_before_destroy - count_after_destroy) == 10
    assert Repo.count(scope) == 0
  end
end
