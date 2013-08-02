defmodule Atlas.Schema do
  alias Atlas.Database.Client

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
      Module.register_attribute __MODULE__, :fields, accumulate: true,
                                                     persist: false
      import unquote(__MODULE__)

      @table nil
      @primary_key nil
      @default_primary_key "id"

      @before_compile unquote(__MODULE__)
    end
  end


  defmacro __before_compile__(_env) do
    quote do
      @table to_binary(@table)
      @primary_key to_binary(@primary_key || @default_primary_key)

      def __atlas__(:table), do: @table

      defrecord Record, fields_to_kwlist(@fields)

      def __atlas__(:fields), do: @fields

      def primary_key_value(record), do: Atlas.Record.get(record, binary_to_atom(@primary_key))

      def raw_query_results_to_records(results) do
        results
        |> Enum.map(fn row -> raw_kwlist_to_field_types(row) end)
        |> Enum.map(fn row -> Record.new(row) end)
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

      def value_to_field_type(value, :string) when is_binary(value), do: value
      def value_to_field_type(value, :string), do: to_binary(value)

      def value_to_field_type(value, :integer) when is_integer(value), do: value
      def value_to_field_type(value, :integer), do: elem(String.to_integer(value), 0)


      def value_to_field_type(value, :float) when is_float(value), do: value
      def value_to_field_type(value, :float), do: elem(String.to_float(value), 0)

      def value_to_field_type(value, :boolean) when is_boolean(value), do: value
      def value_to_field_type(value, :boolean), do: binary_to_atom(to_binary(value)) == true

      def value_to_field_type(value, :datetime) when is_binary(value), do: value
      def value_to_field_type(value, :datetime), do: value
    end
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