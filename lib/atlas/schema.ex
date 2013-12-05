defmodule Atlas.Schema do
  import Atlas.FieldConverter

  @moduledoc """
  Provides schema definitions and Record generation through a `field` macro and
  `__MODULE__.Record` record to hold model state.
  `field` definitions provide handling conversion of binary database results
  into schema defined types.

  Field Types
    :string
    :integer
    :float
    :boolean

  `field` accepts the column name as its first argument, followed by a field type, and
  finally an optional default value as the last argument

  Examples

    defmodule User do
      use Atlas.Model

      field :email, :string
      field :active, :boolean, default: true
    end

    iex> User.Record.new
    User.Record[active: true, email: nil]
  """

  defmacro __using__(_options) do
    quote do
      use Atlas.Relationships
      Module.register_attribute __MODULE__, :fields, accumulate: true,
                                                     persist: false
      import unquote(__MODULE__)

      @table nil
      @primary_key nil
      @default_primary_key :id

      @before_compile unquote(__MODULE__)
    end
  end


  defmacro __before_compile__(_env) do
    quote do
      @primary_key (@primary_key || @default_primary_key)

      defrecord Preloaded, preloaded_fields(__MODULE__, @belongs_to, @has_many)
      defrecord Record, record_fields(@fields, __MODULE__, __MODULE__.Preloaded.new)

      def __atlas__(:table), do: @table
      def __atlas__(:fields), do: @fields

      def table, do: @table

      def primary_key, do: @primary_key

      def primary_key_value(record), do: Atlas.Record.get(record, @primary_key)

      def to_list(record), do: Atlas.Record.to_list(record)

      def raw_query_results_to_records(results) do
        results
        |> Enum.map(fn row -> raw_kwlist_to_field_types(row) end)
        |> Enum.map(fn row -> __MODULE__.Record.new(row) end)
      end

      def raw_kwlist_to_field_types(kwlist) do
        Enum.map kwlist, fn {key, val} ->
          {key, value_to_field_type(val, field_type_for_name(key))}
        end
      end

      def field_type_for_name(field_name) do
        field = @fields |> Enum.find(fn field -> elem(field, 0) == field_name end)
        if field, do: elem(field, 1)
      end

      @doc """
      Returns the attribute value from the record converted to its field type
      """
      def get(record, attribute) do
        value_to_field_type(
          Atlas.Record.get(record, attribute),
          field_type_for_name(attribute)
        )
      end

      @doc """
      Return the preloaded association results for the given record

      record - The __MODULE__.Record
      association_name - The atom of the association name

      Examples

        iex> user = Repo.first User.preloads(:orders) |> User.where(id: 5)
        [User.Record[id: 5, __preloaded__: User.Preloaded[orders: [Order.Record[id: 123..]
        iex> User.preloaded(user, :orders)
        [Order.Record[id: 123...]]

      """
      def preloaded(record, association_name) do
        Atlas.Record.get(record.__preloaded__, association_name)
      end
    end
  end

  def record_fields(fields, model, preload_record) do
    fields_to_kwlist(fields) ++ [model: model, __preloaded__: preload_record]
  end

  @doc """
  Return all defined preloaded fields for has_many and belongs_to relationships
  """
  def preloaded_fields(_model, belongs_to, has_many) do
    Enum.map(belongs_to, fn rel -> {rel.name, nil} end)
    |> Kernel.++(Enum.map(has_many, fn rel -> {rel.name, []} end))
  end

  @doc """
  Converts @fields attribute to keyword list to be used for Record definition
  iex> Schema.fields_to_kwlist([{:active, :boolean, [default: true]}, {:id, :integer, []}])
  [id: nil, active: true]
  """
  def fields_to_kwlist(fields) do
    Enum.map fields, fn field -> {elem(field, 0), default_for_field(field)} end
  end

  def default_for_field({_field_name, _type, options, _func}) do
    Keyword.get options, :default, nil
  end

  defmacro field(field_name, field_type, options // [], func // nil) do
    quote do
      @fields {unquote(field_name), unquote(field_type), unquote(options), unquote(func)}
    end
  end
end
