Code.require_file "test_helper.exs", __DIR__

defmodule Atlas.RepoTest do
  use ExUnit.Case
  use Atlas.PersistenceTestHelper

  setup_all do
    create_user(id: 1, name: "older", age: 6, state: "OH", active: true)
    create_user(id: 2, name: "younger", age: 5, state: "OH", active: true)
    :ok
  end

  test "#find with model and primary key finds model record by primary key value" do
    assert Repo.find(User, 1).name == "older"
    assert Repo.find(User, 2).name == "younger"
    assert Repo.find(User, 0) == nil
  end

  test "#find with query scope and primary key value" do
    assert Repo.find(User.where(name: "older"), 1).name == "older"
    assert Repo.find(User.where(name: "older"), 2) == nil
    assert Repo.find(User.where(name: "older"), 0) == nil
  end

  test "#first with no previous relation" do
    assert Repo.first(User).name == "older"
  end

  test "#first with previous relation" do
    assert (User.where(name: "younger") |> Repo.first).name == "younger"
  end

  test "#first with ASC order" do
    assert (User.order(age: :asc) |> Repo.first).name == "younger"
  end

  test "#first with DESC order" do
    assert (User.order(age: :desc) |> Repo.first).name == "older"
  end

  test "#last with no previous relation" do
    assert Repo.last(User).name == "older"
  end

  test "#last with previous relation" do
    assert (User.where(name: "younger") |> Repo.last).name == "younger"
  end

  test "#last with ASC order" do
    assert (User.order(age: :asc) |> Repo.last).name == "older"
  end

  test "#last with DESC order" do
    assert (User.order(age: :desc) |> Repo.last).name == "younger"
  end


  test "#select returns Records witih only selected field set" do
    record = User.select(:id) |> Repo.first
    assert record.id == Repo.first(User).id
    refute record.name
    refute record.name == Repo.first(User).name
  end


  test "#where finds record based on attributes with keyword list" do
    assert (User.where(name: "younger") |> Repo.first).age == 5
  end

  test "#where finds record based on attributes with string bound query" do
    assert (User.where("lower(name) = lower(?)", "younger") |> Repo.first).age == 5
  end

  test "#where finds record based on attributes with string query" do
    assert (User.where("lower(name) = 'younger'") |> Repo.first).age == 5
  end

  test "#all converts relation into list of Records" do
    records = User.where("age > 5") |> Repo.all
    assert Enum.count(records) == 1
    assert Enum.first(records).name == "older"
  end

  test "#all returns empty list when query macthes zero records" do
    records = User.where("age > 500") |> Repo.all
    assert Enum.count(records) == 0
  end


  test "#count returns the number of found records" do
    assert (User.where("age > ?", 5) |> Repo.count) == 1
    assert (User.where("age > ?", 50) |> Repo.count) == 0
  end

  test "#count ignores order by" do
    assert (User.order(id: :asc) |> User.where("age > ?", 5) |> Repo.count) == 1
  end
end
