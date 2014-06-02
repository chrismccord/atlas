Code.require_file "../test_helper.exs", __DIR__

defmodule Atlas.PersistenceTest do
  use ExUnit.Case
  use Atlas.PersistenceTestHelper

  defmodule Manager do
    use Atlas.Validator
    validates_numericality_of :age, greater_than_or_equal: 20
  end

  setup_all do
    create_user(name: "older", age: 6, state: "OH", active: true)
    create_user(name: "younger", age: 5, state: "OH", active: true)
    :ok
  end

  test "persisted? returns true if record has primary key" do
    assert Repo.persisted?(%User{id: 1}, User)
  end
  test "persisted? returns false if record has no primary key" do
    refute Repo.persisted?(%User{id: nil}, User)
  end

  test "#update updates the records attributes to the database with valid model" do
    record = Repo.first(User.where(name: "older"))
    assert record.age == 6
    {:ok, _} = User.validate(record)
    {:ok, record} = Repo.update(record, [age: 18], as: User)
    assert record.age == 18
    assert Repo.first(User.where(name: "older")).age == 18
  end
  test "#update does not update database and returns error list when invalid" do
    record = Repo.first(User.where(name: "older"))
    age_was = Repo.first(User.where(name: "older")).age

    {:ok, _} = User.validate(record)
    {:error, record_with_failed_attrs, errors} = Repo.update(record, [age: 0], as: User)
    {:error, _, _} = User.validate(record_with_failed_attrs)
    assert record_with_failed_attrs.age == 0
    assert :age in Keyword.keys(errors)
    assert Repo.first(User.where(name: "older")).age == age_was
  end
  test "#update with additional behavior applies extra validations" do
    {:ok, record} = Repo.create(User, [name: "Future Manager", age: 18], as: User)
    {:error, record, _reasons} = Repo.update(record, [age: 11], as: [User, Manager])
    assert record.age == 11
    assert Repo.first(User.where(name: "Future Manager")).age == 18
  end

  test "#create with keyword list inserts record attributes into the database" do
    refute Repo.first(User.where(name: "José"))
    {:ok, _user} = Repo.create(User, [name: "José", age: 30], as: User)
    assert Repo.first(User.where(name: "José"))
  end
  test "#create with record inserts record attributes into the database" do
    refute Repo.first(User.where(name: "Joe"))
    {:ok, _user} = Repo.create(User, %User{name: "Joe", age: 30}, as: User)
    assert Repo.first(User.where(name: "Joe"))
  end

  test "#destroy deletes the record from the database" do
    {:ok, user} = Repo.create(User, [name: "Bob", age: 30], as: User)
    assert Repo.first(User.where(name: "Bob"))
    {:ok, _} = Repo.destroy(user, as: User)
    refute Repo.first(User.where(name: "Bob"))
  end
  test "#destroy sets the record primary key to nil" do
    {:ok, user} = Repo.create(User, [name: "Bob", age: 30], as: User)
    assert user.id != nil
    {:ok, user} = Repo.destroy(user, as: User)
    assert user.id == nil
    refute Repo.persisted?(user, User)
  end

  test "#destroy_all with relation deletes all matching records from database" do
    Enum.each 1..10, fn i ->
      {:ok, _} = Repo.create(User, [name: "Bob#{i}", age: i + 100], as: User)
    end
    scope = User.where("age > ?", 100)
    count_before_destroy = scope |> Repo.count
    assert Repo.destroy_all(scope)
    count_after_destroy = scope |> Repo.count
    assert count_before_destroy != count_after_destroy
    assert (count_before_destroy - count_after_destroy) == 10
    assert Repo.count(scope) == 0
  end

  test "#destroy_all with list of records deletes all records from database" do
    Enum.each 1..10, fn i ->
      {:ok, _user} = Repo.create(User, [name: "Bob#{i}", age: i + 100], as: User)
    end
    scope = User.where("age > ?", 100)
    records = Repo.all(scope)
    count_before_destroy = scope |> Repo.count

    assert Repo.destroy_all(records, User)
    count_after_destroy = scope |> Repo.count
    assert count_before_destroy != count_after_destroy
    assert (count_before_destroy - count_after_destroy) == 10
    assert Repo.count(scope) == 0
  end
end
