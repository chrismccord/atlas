Code.require_file "../test_helper.exs", __DIR__

defmodule Atlas.QueryBuilderTest do
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
    assert Model.where(name: "chris").wheres == [{"\"models\".\"name\" = ?", ["chris"]}]
  end

  test "wheres with keyword list with multiple keys" do
    assert Model.where(name: "chris", age: 26).wheres ==
      [{"\"models\".\"name\" = ? \nAND \"models\".\"age\" = ?", ["chris", 26]}]
  end

  test "chaining wheres with keyword list" do
    relation = Model.where(name: "chris", age: 26) |> Model.where(active: true)
    assert relation.wheres == [
      {"\"models\".\"name\" = ? \nAND \"models\".\"age\" = ?", ["chris", 26]},
      {"\"models\".\"active\" = ?", [true]}
    ]
  end


  test "chaining query string and keyword list queries" do
    relation = Model.where(name: "chris", age: 26)
               |> Model.where(active: true)
               |> Model.where("email IS NOT NULL")
               |> Model.where("lower(email) = ?", "chris@atlas.dev")
               |> Model.where("state = ? OR state = ?", ["complete", "in_progress"])

    assert relation.wheres == [
      {"\"models\".\"name\" = ? \nAND \"models\".\"age\" = ?", ["chris", 26]},
      {"\"models\".\"active\" = ?", [true]},
      {"email IS NOT NULL", []},
      {"lower(email) = ?", ["chris@atlas.dev"]},
      {"state = ? OR state = ?", ["complete", "in_progress"]}
    ]
  end


  test "#first with no previous relation" do
    assert Model.first.name == "older"
  end

  test "#first with previous relation" do
    assert (Model.where(name: "younger") |> Model.first).name == "younger"
  end

  test "#first with ASC order" do
    assert (Model.order(age: :asc) |> Model.first).name == "younger"
  end

  test "#first with DESC order" do
    assert (Model.order(age: :desc) |> Model.first).name == "older"
  end


  test "#last with no previous relation" do
    assert Model.last.name == "older"
  end

  test "#last with previous relation" do
    assert (Model.where(name: "younger") |> Model.last).name == "younger"
  end

  test "#last with ASC order" do
    assert (Model.order(age: :asc) |> Model.last).name == "older"
  end

  test "#last with DESC order" do
    assert (Model.order(age: :desc) |> Model.last).name == "younger"
  end


  test "#select returns Records witih only selected field set" do
    record = Model.select(:id) |> Model.first
    assert record.id == Model.first.id
    refute record.name
    refute record.name == Model.first.name
  end


  test "#where finds record based on attributes with keyword list" do
    assert (Model.where(name: "younger") |> Model.first).age == 5
  end

  test "#where finds record based on attributes with string bound query" do
    assert (Model.where("lower(name) = lower(?)", "younger") |> Model.first).age == 5
  end

  test "#where finds record based on attributes with string query" do
    assert (Model.where("lower(name) = 'younger'") |> Model.first).age == 5
  end

  test "#to_records converts relation into list of Records" do
    records = Model.where("age > 5") |> Model.to_records
    assert Enum.count(records) == 1
    assert Enum.first(records).name == "older"
  end

  test "#to_records returns empty list when query macthes zero records" do
    records = Model.where("age > 500") |> Model.to_records
    assert Enum.count(records) == 0
  end


  test "#count returns the number of found records" do
    assert (Model.where("age > ?", 5) |> Model.count) == 1
    assert (Model.where("age > ?", 50) |> Model.count) == 0
  end

  test "#count ignores order by" do
    assert (Model.order(id: :asc) |> Model.where("age > ?", 5) |> Model.count) == 1
  end

  test "#limit limits records given number with no prior relation" do
    assert Model.limit(1) |> Model.to_records |> Enum.count == 1
  end

  test "#limit limits records given number with prior relation" do
    assert Model.where("age > 1") |> Model.limit(1) |> Model.to_records |> Enum.count == 1
  end

  test "#limit overwrites previous limit" do
    assert Model.limit(2) |> Model.limit(1) |> Model.to_records |> Enum.count == 1
  end


  test "#offset offsets records given number with no prior relation" do
    assert (Model.order(age: :asc) |> Model.offset(0) |> Model.first).age == 5
    assert (Model.order(age: :asc) |> Model.offset(1) |> Model.first).age == 6
  end

  test "#offset offsets records given number with prior relation" do
    assert (Model.offset(0) |> Model.order(age: :asc) |> Model.first).age == 5
    assert (Model.offset(1) |> Model.order(age: :asc) |> Model.first).age == 6
  end

  test "#offset overwrites previous offset" do
    assert (Model.offset(3) |> Model.offset(1) |> Model.order(age: :asc) |> Model.first).age == 6
  end

  test "#list_to_binding_placeholders transforms list into binding placeholders for query" do
    assert Atlas.QueryBuilder.list_to_binding_placeholders([1, 2, 3]) == "?, ?, ?"
    assert Atlas.QueryBuilder.list_to_binding_placeholders([1]) == "?"
    assert Atlas.QueryBuilder.list_to_binding_placeholders([]) == ""
  end
end
