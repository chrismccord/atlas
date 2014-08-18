defmodule Atlas.Accessors do

  @moduledoc """
  Accessors for assigning and retrieving model attributes are automatically defined
  from the schema field definitions.

  By default, Accessors are simply pass-throughs to the raw record setter and getter
  values; however, accessors can be overriden by the module for extended behavior
  and transformations before writing to, or after reading from the database.

  Assign functions transform attributes when creating a new Struct via `Model.new`.

  Example attribute assignment

    defmodule User do
      use Atlas.Model
      field :email, :string
      field :name,  :string

      def assign(user, :email, value), do: %User{user | email: String.downcase(value)}
    end

    iex> User.assign(user, :email, "USER@example.com")
    %User{email: "user@example.com"}

    iex> User.new(email, "USER@example.com")
    %User{email: "user@example.com"}


  Example attribute retrieval

    defmodule User do
      use Atlas.Model
      field :email, :string
      field :name,  :string

      def email(user), do: user.email |> String.upcase
    end

    iex> user = User.new(email: "chris@example.com")
    iex> User.email(user)
    CHRIS@EXAMPLE.COM

  """

  defmacro __using__(_options) do
    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote unquote: false do

      @doc """
      Instatiate a %__MODULE__{}, passing attributes through all default and custom setters

      Examples
        defmodule User do
          use Atlas.Model
          field :email, :string

          def assign(user, :email, value), do: %{user | email: String.downcase(value)}
        end

        iex> User.new(email: "USER@example.com")
        %User{email: "user@example.com"}

        iex> User.new(%User{email: "USER@example.com"})
        %User{email: "user@example.com"}

      """
      def new(attributes \\ [])
      def new(attributes) when is_list(attributes) do
        assign(struct(__MODULE__, attributes), attributes)
      end
      def new(map) when is_map(map) do
        new to_list(map)
      end

      @doc """

      Assign given attributes to the record, passing values through default and custom setters

      Examples
        defmodule User do
          use Atlas.Model
          field :email, :string

          def assign(user, :email, value) do
            %{user | email: String.downcase(value)}
          end
        end

        iex> user = User.new
        %User{email: nil}

        iex> User.assign(user, email: "USER@example.com")
        %User{email: "user@example.com"}

      """
      def assign(record, attributes) when is_map(record) and is_list(attributes) do
        Enum.reduce attributes, record, fn {key, value}, record ->
          assign(record, key, value)
        end
      end
      def assign(record, key, value) do
        Map.put(record, key, value)
      end

      Enum.each @fields, fn {name, _, _, _} ->
        unless Module.defines?(__MODULE__, {name, 1}) do
          @doc "Default getter for #{name}. Returns `record.#{name}`"
          def unquote(name)(record) do
            Map.get(record, unquote(name))
          end
        end
      end

    end
  end
end
