Code.require_file "test_helper.exs", __DIR__

defmodule Atlas.RelationshipsTest do
  use ExUnit.Case
  use Atlas.PersistenceTestHelper

  setup_all do
    create_user(id: 1, name: "chris")
    create_user(id: 2, name: "bob")
    create_user(id: 3, name: "ted")
    create_post(id: 12, message: "this is a post by chris", user_id: 1)
    create_post(id: 13, message: "this is a post by bob", user_id: 2)
    create_post(id: 14, message: "this is another post by bob", user_id: 2)
    :ok
  end

  test "belongs_to finds the related model by primary key using foreign key of relationship" do
    chris = Repo.find(User, 1)
    bob = Repo.find(User, 2)

    assert Repo.find(Post, 12) |> Post.user |> Repo.first == chris
    assert Repo.find(Post, 13) |> Post.user |> Repo.first == bob
    assert Repo.find(Post, 14) |> Post.user |> Repo.first == bob
  end


  test "has_many finds the related models by primary key using foreign key of relationship" do
    chris = Repo.find(User, 1)
    bob = Repo.find(User, 2)
    ted = Repo.find(User, 3)

    assert Repo.count(User.posts(chris)) == 1
    assert Repo.count(User.posts(bob)) == 2
    assert Repo.count(User.posts(ted)) == 0

    assert User.posts(chris) |> Repo.first |> Post.message == "this is a post by chris"
    assert User.posts(bob) |> Repo.first |> Post.message == "this is a post by bob"
    assert User.posts(ted) |> Repo.first == nil
  end
end

