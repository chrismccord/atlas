Code.require_file "test_helper.exs", __DIR__

defmodule Atlas.AccessorsTest do
  use ExUnit.Case

  defmodule User do
    use Atlas.Model

    field :id, :integer
    field :email, :string
    field :username, :string

    def username(user) do
      String.upcase user.username
    end

    def assign(user, :email, value) do
      email = String.downcase(value)
      %{user| email: email, username: email}
    end
  end


  test "#assign with assignment key, value transform creates Struct with processed setters" do
    user = User.new(email: "foo@BAR.com", id: 123)
    assert user.email == "foo@bar.com"
  end

  test "#assign with assignment record, key, val transform creates Struct with processed setters" do
    user = User.new(email: "foo@BAR.com", id: 123)
    assert user.email == "foo@bar.com"
    assert user.username == "foo@bar.com"
  end

  test "fields without custom setter set raw value" do
    user = User.new(email: "foo@BAR.com", id: 123)
    assert user.id == 123
  end

  test "#new with keyword list transforms fields with setters and returns struct" do
    user = User.new(email: "foo@BAR.com", id: 123)
    assert user.email == "foo@bar.com"
    assert user.username == "foo@bar.com"
  end

  test "#new with Struct returns record fields passed through setters" do
    user = User.new(User.new(email: "CHRIS@example.com"))
    assert user.email == "chris@example.com"
  end

  test "custom getters transforms record field value" do
    user = User.new(username: "chris")
    assert User.username(user) == "CHRIS"
  end

  test "default getters returns raw record field value" do
    user = User.new(id: 100)
    assert User.id(user) == 100
  end
end
