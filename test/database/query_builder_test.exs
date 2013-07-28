Code.require_file "../test_helper.exs", __DIR__

defmodule Atlas.QueryBuilderTest do
  use ExUnit.Case

  defmodule Model do
    use Atlas.Model
    @table :models
    @primary_key :id

    field :name, :string
    field :state, :string
    field :active, :boolean
    field :age, :integer
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
  end

  test "#first with previous relation" do
  end

  test "#first with ASC order" do
  end

  test "#first with DESC order" do
  end

  test "#last with no previous relation" do
  end

  test "#last with previous relation" do
  end

  test "#last with ASC order" do
  end

  test "#last with DESC order" do
  end

end
