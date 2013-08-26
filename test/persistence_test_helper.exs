defmodule Atlas.PersistenceTestHelper do
  alias Atlas.Database.Client

  defmacro __using__(_options) do
    quote do
      def create_table do
        drop_table
        sql = """
        CREATE TABLE models (
          id SERIAL PRIMARY KEY,
          name varchar(255),
          state varchar(255),
          active boolean,
          age int8
        )
        """
        {:ok, _} = Client.raw_query(sql , Repo)

      end

      def drop_table do
        {:ok, _} = Client.raw_query "DROP TABLE IF EXISTS models", Repo
      end

      defmodule User do
        use Atlas.Model
        @table :models
        @primary_key :id

        field :id, :integer
        field :name, :string
        field :state, :string
        field :active, :boolean
        field :age, :integer
        validates_numericality_of :age, greater_than: 0, less_than: 150

        has_many :posts, foreign_key: :user_id, model: Post
      end

      defmodule Post do
        use Atlas.Model
        @table :posts
        @primary_key :id

        field :id, :integer
        field :name, :string
        field :state, :string
        field :active, :boolean
        field :age, :integer
        validates_numericality_of :age, greater_than: 0, less_than: 150

        belongs_to :user, foreign_key: :user_id, model: User
      end

      def create_user(attributes) do
        bindings = Enum.map_join 1..Enum.count(attributes), ", ", fn i -> "$#{i}" end
        columns  = Keyword.keys(attributes) |> Enum.join ", "
        values   = Keyword.values(attributes)

        {:ok, _} = Client.raw_prepared_query(
          "INSERT INTO models (#{columns}) VALUES(#{bindings})",
           values,
           Repo
        )
      end

      setup_all do
        create_table
        :ok
      end

      teardown_all do
        drop_table
        :ok
      end
    end
  end
end