Code.require_file "../test_helper.exs", __DIR__

defmodule Atlas.ClientTest do
  use ExUnit.Case
  use Atlas.PersistenceTestHelper
  alias Atlas.Database.Client

  setup_all do
    create_user(id: 1, name: "older", age: 6, state: "OH", active: true)
    create_user(id: 2, name: "younger", age: 5, state: "OH", active: true)
    :ok
  end


  test "#raw_query returns raw results from database driver query" do
    {:ok, { _, _, rows}} = Client.raw_query("SELECT id FROM models WHERE id = 1", Repo)
    row = Enum.first(rows)
    assert Enum.first(row) == "1"
  end

  test "#raw_prepared_query returns raw results from database driver prepared query" do
    {:ok, { _, _, rows}} = Client.raw_prepared_query("SELECT id FROM models WHERE id = ?", [1], Repo)
    row = Enum.first(rows)
    assert Enum.first(row) == "1"
  end

  test "#execute_query returns query results as keyword lists" do
    {:ok, results} = Client.execute_query("SELECT id FROM models WHERE id = 1", Repo)
    row = Enum.first results
    assert row[:id] == "1"
  end

  test "#execute_prepared_query returns the results as keyword lists" do
    {:ok, results} = Client.execute_prepared_query("SELECT id FROM models WHERE id = ?", [1], Repo)
    row = Enum.first results
    assert row[:id] == "1"
  end
end
