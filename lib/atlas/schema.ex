defmodule Atlas.Schema do
  alias Atlas.Database.Client
  defmacro __using__(_options) do
    quote do
      Module.register_attribute __MODULE__, :fields, accumulate: true,
                                                     persist: false

      import unquote(__MODULE__)

      @before_compile unquote(__MODULE__)
    end
  end


  defmacro __before_compile__(_env) do
    quote do
      defrecord Record, fields_to_kwlist(@fields)

      def where(query) do
        Client.query_to_kwlist(query)
        |> Enum.map(fn row -> raw_kwlist_to_field_types(row) end)
        |> Enum.map(fn row -> Record.new(row) end)
      end

      def raw_kwlist_to_field_types(kwlist) do
        Enum.map kwlist, fn {key, val} ->
          {key, value_to_field_type(val, field_type_for_name(key))}
        end
      end

      def field_type_for_name(field_name) do
        @fields
        |> Enum.find(fn field -> elem(field, 0) == field_name end)
        |> elem(1)
      end

      def value_to_field_type(value, :string), do: to_binary(value)
      def value_to_field_type(value, :integer), do: elem(String.to_integer(value), 0)
      def value_to_field_type(value, :float), do: elem(String.to_float(value), 0)
      def value_to_field_type(value, :boolean) when is_boolean(value), do: value
      def value_to_field_type(value, :boolean), do: binary_to_atom(to_binary(value)) == true
    end
  end

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

  def create_field_functions({field_name, :string, options}) do

  end

  def create_field_functions({field_name, :integer, options}) do

  end

  def create_field_functions({field_name, :float, options}) do

  end

  def create_field_functions({field_name, :datetme, options}) do

  end

  def create_field_functions({field_name, :boolean, options}) do

  end
end