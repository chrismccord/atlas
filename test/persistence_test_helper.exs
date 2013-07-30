defmodule Atlas.PersistenceTestHelper do
  alias Atlas.Database.Client

  defmacro __using__(_options) do
    quote do
      def create_table do
        drop_table
        {:ok, _} = Client.raw_query """
        CREATE TABLE models (
          id int8 NOT NULL,
          name varchar(255),
          state varchar(255),
          active boolean,
          age int8,
          PRIMARY KEY (id)
        )
        """
      end

      def drop_table do
        {:ok, _} = Client.raw_query "DROP TABLE IF EXISTS models"
      end

      def create_user(attributes) do
        bindings = Enum.map_join 1..Enum.count(attributes), ", ", fn i -> "$#{i}" end
        columns  = Keyword.keys(attributes) |> Enum.join ", "
        values   = Keyword.values(attributes)

        {:ok, _} = Client.raw_prepared_query(
          "INSERT INTO models (#{columns}) VALUES(#{bindings})",
           values
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