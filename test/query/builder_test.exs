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
    assert User.where("name IS NOT NULL").wheres == [{"name IS NOT NULL", []}]
  end

  test "chaining wheres with query string only" do
    relation = User.where("name IS NOT NULL") |> User.where("age > 18")
    assert relation.wheres == [{"name IS NOT NULL", []}, {"age > 18", []}]
  end

  test "wheres with query string and bound values" do
    assert User.where("name = ?", ["chris"]).wheres == [{"name = ?", ["chris"]}]
  end

  test "wheres with query string and single bound value" do
    assert User.where("name = ?", "chris").wheres == [{"name = ?", ["chris"]}]
  end

  test "chaining wheres with query string and bound values" do
    relation = User.where("name = ?", ["chris"]) |> User.where("age = ?", [18])
    assert relation.wheres == [{"name = ?", ["chris"]}, {"age = ?", [18]}]
  end


  test "wheres with keyword list with single key" do
    assert User.where(name: "chris").wheres == [[name: "chris"]]
  end

  test "wheres with keyword list with multiple keys" do
    assert User.where(name: "chris", age: 26).wheres == [[name: "chris", age: 26]]
  end

  test "chaining wheres with keyword list" do
    relation = User.where(name: "chris", age: 26) |> User.where(active: true)
    assert relation.wheres == [[name: "chris", age: 26], [active: true]]
  end


  test "chaining query string and keyword list queries" do
    relation = User.where(name: "chris", age: 26)
               |> User.where(active: true)
               |> User.where("email IS NOT NULL")
               |> User.where("lower(email) = ?", "chris@atlas.dev")
               |> User.where("state = ? OR state = ?", ["complete", "in_progress"])

    assert relation.wheres == [
      [name: "chris", age: 26],
      [active: true],
      {"email IS NOT NULL", []},
      {"lower(email) = ?", ["chris@atlas.dev"]},
      {"state = ? OR state = ?", ["complete", "in_progress"]}
    ]
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


  test "Repo#count ignores order by" do
    assert (User.order(id: :asc) |> User.where("age > ?", 5) |> Repo.count) == 1
  end

  test "#limit limits records given number with no prior relation" do
    assert User.limit(1) |> Repo.all |> Enum.count == 1
  end

  test "#limit limits records given number with prior relation" do
    assert User.where("age > 1") |> User.limit(1) |> Repo.all |> Enum.count == 1
  end

  test "#limit overwrites previous limit" do
    assert User.limit(2) |> User.limit(1) |> Repo.all |> Enum.count == 1
  end


  test "#offset offsets records given number with no prior relation" do
    assert (User.order(age: :asc) |> User.offset(0) |> Repo.first).age == 5
    assert (User.order(age: :asc) |> User.offset(1) |> Repo.first).age == 6
  end

  test "#offset offsets records given number with prior relation" do
    assert (User.offset(0) |> User.order(age: :asc) |> Repo.first).age == 5
    assert (User.offset(1) |> User.order(age: :asc) |> Repo.first).age == 6
  end

  test "#offset overwrites previous offset" do
    assert (User.offset(3) |> User.offset(1) |> User.order(age: :asc) |> Repo.first).age == 6
  end

  test "#list_to_binding_placeholders transforms list into binding placeholders for query" do
    assert Atlas.Query.Builder.list_to_binding_placeholders([1, 2, 3]) == "?, ?, ?"
    assert Atlas.Query.Builder.list_to_binding_placeholders([1]) == "?"
    assert Atlas.Query.Builder.list_to_binding_placeholders([]) == ""
  end

  test "#join with empty join expression returns nil" do
    assert User.scoped |> Repo.joins_to_sql == nil
  end

  test "#join with relationship name converts relation to sql" do
    assert User.joins(:posts) |> Repo.joins_to_sql ==
      "INNER JOIN \"posts\" ON \"posts\".\"user_id\" = \"users\".id"
  end

  test "#join with raw sql expression returns sql expression" do
    assert User.joins("INNER JOIN \"posts\" ON \"posts\".\"user_id\" = \"users\".user_id") |> Repo.joins_to_sql ==
      "INNER JOIN \"posts\" ON \"posts\".\"user_id\" = \"users\".user_id"
  end

  test "#join with multiple joins expressions returns array of processed join expressions as sql" do
    query = User.joins(:posts) |> User.joins("INNER JOINS foo ON foo.id = bar.foo_id")


    assert Repo.joins_to_sql(query) == Enum.join([
      "INNER JOIN \"posts\" ON \"posts\".\"user_id\" = \"users\".id",
      "INNER JOINS foo ON foo.id = bar.foo_id"
    ], "\n")
  end
end
