Code.require_file "../test_helper.exs", __DIR__

defmodule Atlas.Query.BuilderTest do
  use ExUnit.Case
  use Atlas.PersistenceTestHelper

  setup_all do
    create_user(id: 1, name: "older", age: 6, state: "OH", active: true)
    create_user(id: 2, name: "younger", age: 5, state: "OH", active: true)
    :ok
  end

  test "wheres with query string only" do
    assert Model.where("name IS NOT NULL").wheres == [{"name IS NOT NULL", []}]
  end

  test "chaining wheres with query string only" do
    relation = Model.where("name IS NOT NULL") |> Model.where("age > 18")
    assert relation.wheres == [{"name IS NOT NULL", []}, {"age > 18", []}]
  end

  test "wheres with query string and bound values" do
    assert Model.where("name = ?", ["chris"]).wheres == [{"name = ?", ["chris"]}]
  end

  test "wheres with query string and single bound value" do
    assert Model.where("name = ?", "chris").wheres == [{"name = ?", ["chris"]}]
  end

  test "chaining wheres with query string and bound values" do
    relation = Model.where("name = ?", ["chris"]) |> Model.where("age = ?", [18])
    assert relation.wheres == [{"name = ?", ["chris"]}, {"age = ?", [18]}]
  end


  test "wheres with keyword list with single key" do
    assert Model.where(name: "chris").wheres == [[name: "chris"]]
  end

  test "wheres with keyword list with multiple keys" do
    assert Model.where(name: "chris", age: 26).wheres == [[name: "chris", age: 26]]
  end

  test "chaining wheres with keyword list" do
    relation = Model.where(name: "chris", age: 26) |> Model.where(active: true)
    assert relation.wheres == [[name: "chris", age: 26], [active: true]]
  end


  test "chaining query string and keyword list queries" do
    relation = Model.where(name: "chris", age: 26)
               |> Model.where(active: true)
               |> Model.where("email IS NOT NULL")
               |> Model.where("lower(email) = ?", "chris@atlas.dev")
               |> Model.where("state = ? OR state = ?", ["complete", "in_progress"])

    assert relation.wheres == [
      [name: "chris", age: 26],
      [active: true],
      {"email IS NOT NULL", []},
      {"lower(email) = ?", ["chris@atlas.dev"]},
      {"state = ? OR state = ?", ["complete", "in_progress"]}
    ]
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


  test "Repo#count ignores order by" do
    assert (Model.order(id: :asc) |> Model.where("age > ?", 5) |> Repo.count) == 1
  end

  test "#limit limits records given number with no prior relation" do
    assert Model.limit(1) |> Repo.all |> Enum.count == 1
  end

  test "#limit limits records given number with prior relation" do
    assert Model.where("age > 1") |> Model.limit(1) |> Repo.all |> Enum.count == 1
  end

  test "#limit overwrites previous limit" do
    assert Model.limit(2) |> Model.limit(1) |> Repo.all |> Enum.count == 1
  end


  test "#offset offsets records given number with no prior relation" do
    assert (Model.order(age: :asc) |> Model.offset(0) |> Repo.first).age == 5
    assert (Model.order(age: :asc) |> Model.offset(1) |> Repo.first).age == 6
  end

  test "#offset offsets records given number with prior relation" do
    assert (Model.offset(0) |> Model.order(age: :asc) |> Repo.first).age == 5
    assert (Model.offset(1) |> Model.order(age: :asc) |> Repo.first).age == 6
  end

  test "#offset overwrites previous offset" do
    assert (Model.offset(3) |> Model.offset(1) |> Model.order(age: :asc) |> Repo.first).age == 6
  end

  test "#list_to_binding_placeholders transforms list into binding placeholders for query" do
    assert Atlas.Query.Builder.list_to_binding_placeholders([1, 2, 3]) == "?, ?, ?"
    assert Atlas.Query.Builder.list_to_binding_placeholders([1]) == "?"
    assert Atlas.Query.Builder.list_to_binding_placeholders([]) == ""
  end
end
