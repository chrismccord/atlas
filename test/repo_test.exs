Code.require_file "test_helper.exs", __DIR__

defmodule Atlas.RepoTest do
  use ExUnit.Case
  use Atlas.PersistenceTestHelper

  setup_all do
    create_user(id: 1, name: "older", age: 6, state: "OH", active: true)
    create_user(id: 2, name: "younger", age: 5, state: "OH", active: true)
    :ok
  end

  test "#first with no previous relation" do
    assert Repo.first(Model).name == "older"
  end

  test "#first with previous relation" do
    assert (Model.where(name: "younger") |> Repo.first).name == "younger"
  end

  test "#first with ASC order" do
    assert (Model.order(age: :asc) |> Repo.first).name == "younger"
  end

  test "#first with DESC order" do
    assert (Model.order(age: :desc) |> Repo.first).name == "older"
  end

  test "#last with no previous relation" do
    assert Repo.last(Model).name == "older"
  end

  test "#last with previous relation" do
    assert (Model.where(name: "younger") |> Repo.last).name == "younger"
  end

  test "#last with ASC order" do
    assert (Model.order(age: :asc) |> Repo.last).name == "older"
  end

  test "#last with DESC order" do
    assert (Model.order(age: :desc) |> Repo.last).name == "younger"
  end


  test "#select returns Records witih only selected field set" do
    record = Model.select(:id) |> Repo.first
    assert record.id == Repo.first(Model).id
    refute record.name
    refute record.name == Repo.first(Model).name
  end


  test "#where finds record based on attributes with keyword list" do
    assert (Model.where(name: "younger") |> Repo.first).age == 5
  end

  test "#where finds record based on attributes with string bound query" do
    assert (Model.where("lower(name) = lower(?)", "younger") |> Repo.first).age == 5
  end

  test "#where finds record based on attributes with string query" do
    assert (Model.where("lower(name) = 'younger'") |> Repo.first).age == 5
  end

  test "#all converts relation into list of Records" do
    records = Model.where("age > 5") |> Repo.all
    assert Enum.count(records) == 1
    assert Enum.first(records).name == "older"
  end

  test "#all returns empty list when query macthes zero records" do
    records = Model.where("age > 500") |> Repo.all
    assert Enum.count(records) == 0
  end


  test "#count returns the number of found records" do
    assert (Model.where("age > ?", 5) |> Repo.count) == 1
    assert (Model.where("age > ?", 50) |> Repo.count) == 0
  end

  test "#count ignores order by" do
    assert (Model.order(id: :asc) |> Model.where("age > ?", 5) |> Repo.count) == 1
  end
end
