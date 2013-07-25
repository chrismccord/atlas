Code.require_file "../test_helper.exs", __DIR__

defmodule Atlas.QueryBuilderTest do
  use ExUnit.Case
  import Atlas.QueryBuilder

  test "wheres with query string only" do
    assert where("name IS NOT NULL").wheres == [{"name IS NOT NULL", []}]
  end

  test "chaining wheres with query string only" do
    relation = where("name IS NOT NULL") |> where("age > 18")
    assert relation.wheres == [{"name IS NOT NULL", []}, {"age > 18", []}]
  end

  test "wheres with query string and bound values" do
    assert where("name = ?", ["chris"]).wheres == [{"name = ?", ["chris"]}]
  end

  test "wheres with query string and single bound value" do
    assert where("name = ?", "chris").wheres == [{"name = ?", ["chris"]}]
  end

  test "chaining wheres with query string and bound values" do
    relation = where("name = ?", ["chris"]) |> where("age = ?", [18])
    assert relation.wheres == [{"name = ?", ["chris"]}, {"age = ?", [18]}]
  end


  test "wheres with keyword list with single key" do
    assert where(name: "chris").wheres == [{"name = ?", ["chris"]}]
  end

  test "wheres with keyword list with multiple keys" do
    assert where(name: "chris", age: 26).wheres == [{"name = ? \nAND age = ?", ["chris", 26]}]
  end

  test "chaining wheres with keyword list" do
    relation = where(name: "chris", age: 26) |> where(active: true)
    assert relation.wheres == [{"name = ? \nAND age = ?", ["chris", 26]}, {"active = ?", [true]}]
  end


  test "chaining query string and keyword list queries" do
    relation = where(name: "chris", age: 26)
               |> where(active: true)
               |> where("email IS NOT NULL")
               |> where("lower(email) = ?", "chris@atlas.dev")
               |> where("state = ? OR state = ?", ["complete", "in_progress"])

    assert relation.wheres == [
      {"name = ? \nAND age = ?", ["chris", 26]},
      {"active = ?", [true]},
      {"email IS NOT NULL", []},
      {"lower(email) = ?", ["chris@atlas.dev"]},
      {"state = ? OR state = ?", ["complete", "in_progress"]}
    ]
  end
end
