defmodule Atlas.PersistenceTestHelper do
  alias Atlas.Database.Client

  defmodule User do
    use Atlas.Model
    @table :users
    @primary_key :id

    field :id, :integer
    field :name, :string
    field :state, :string
    field :active, :boolean
    field :age, :integer
    validates_numericality_of :age, greater_than: 0, less_than: 150

    has_many :posts, foreign_key: :user_id, model: Atlas.PersistenceTestHelper.Post
  end

  defmodule Post do
    use Atlas.Model
    @table :posts
    @primary_key :id

    field :id, :integer
    field :message, :string
    field :user_id, :integer

    belongs_to :user, foreign_key: :user_id, model: Atlas.PersistenceTestHelper.User
  end

  defmacro __using__(_options) do
    quote do
      alias Atlas.PersistenceTestHelper.User
      alias Atlas.PersistenceTestHelper.Post

      def create_table do
        drop_table
        sql = """
        CREATE TABLE users (
          id SERIAL PRIMARY KEY,
          name varchar(255),
          state varchar(255),
          active boolean,
          age int8
        )
        """
        {:ok, _} = Client.raw_query(sql , Repo)

        sql = """
        CREATE TABLE posts (
          id SERIAL PRIMARY KEY,
          user_id int8,
          message varchar(255)
        )
        """
        {:ok, _} = Client.raw_query(sql , Repo)

      end

      def drop_table do
        {:ok, _} = Client.raw_query "DROP TABLE IF EXISTS users", Repo
        {:ok, _} = Client.raw_query "DROP TABLE IF EXISTS posts", Repo
      end

      def create_user(attributes) do
        bindings = Enum.map_join 1..Enum.count(attributes), ", ", fn i -> "$#{i}" end
        columns  = Keyword.keys(attributes) |> Enum.join ", "
        values   = Keyword.values(attributes)

        {:ok, _} = Client.raw_prepared_query(
          "INSERT INTO users (#{columns}) VALUES(#{bindings})",
           values,
           Repo
        )
      end

      def create_post(attributes) do
        bindings = Enum.map_join 1..Enum.count(attributes), ", ", fn i -> "$#{i}" end
        columns  = Keyword.keys(attributes) |> Enum.join ", "
        values   = Keyword.values(attributes)

        {:ok, _} = Client.raw_prepared_query(
          "INSERT INTO posts (#{columns}) VALUES(#{bindings})",
           values,
           Repo
        )
      end

      setup_all do
        create_table
        on_exit fn -> drop_table end
        :ok
      end

    end
  end
end
