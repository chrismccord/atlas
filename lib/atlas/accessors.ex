defmodule Atlas.Accessors do

  defmacro __using__(_options) do
    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do

      @doc """
      Instatiate a __MODULE__.Record, passing attributes through all default and custom setters

      Examples
        defmodule User do
          use Atlas.Model
          field :email, :string

          def assign(user, :email, value), do: user.update(email: String.downcase(value))
        end

        iex> User.new(email: "USER@example.com")
        User.Record[email: "user@example.com"]

        iex> User.new(User.Record.new(email: "USER@example.com"))
        User.Record[email: "user@example.com"]

      """
      def new(attributes // []) when is_list(attributes) do
        assign(__MODULE__.Record.new, attributes)
      end
      def new(record) when is_record(record) do
        new to_list(record)
      end

      @doc """

      Assign given attributes to the record, passing values through default and custom setters

      Examples
        defmodule User do
          use Atlas.Model
          field :email, :string

          def assign(user, :email, value), do: user.update(email: String.downcase(value))
        end

        iex> user = User.new
        User.Record[email: nil]

        iex> User.assign(user, email: "USER@example.com")
        User.Record[email: "user@example.com"]

      """
      def assign(record, attributes) when is_record(record) and is_list(attributes) do
        Enum.reduce attributes, record, fn {key, value}, record ->
          assign(record, key, value)
        end
      end
      def assign(record, key, value) do
        record.update([{key, value}])
      end

      Enum.each @fields, fn {name, _, _, _} ->
        unless Module.defines?(__MODULE__, {name, 1}) do
          @doc "Default getter for #{name}. Returns `record.#{name}`"
          def name, quote(do: [record]), [] do
            quote do
              Atlas.Record.get(record, unquote(name))
            end
          end
        end
      end

    end
  end
end
