defmodule Atlas.Model do

  defmacro __using__(_options) do
    quote do
      Module.register_attribute __MODULE__, :validations, accumulate: true, 
                                                          persist: false
      import unquote(__MODULE__)
      import Atlas.Validator
      alias Atlas.Present
      alias Atlas.Count
      alias Atlas.Record
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do

      def validate(record) do
        case errors(record) do
          []      -> {:ok, record}
          errors  -> {:error, errors}
        end
      end

      @doc """
      Returns a keyword list of attributes and error message pairs

      ## Examples

        iex> User.errors(UserRecord.new(name: "Chris"))
        [name: "must be greater than 5 characters"]

      """
      def errors(record) do
        @validations
        |> Enum.map(process_validation_form(record, &1))
        |> Enum.filter(fn error -> error end)
      end

      @doc """
      Returns a list of expanded error messages including attribute names

      ## Examples

        iex> User.full_error_messages(UserRecord.new(name: "Chris"))
        ["name must be greater than 5 characters"]

      """
      def full_error_messages(record) do
        Enum.map errors(record), fn {attribute, error_message} ->
          full_error_message(attribute, error_message)
        end
      end

      @doc """
      Returns an expanded error message for the record given the attribute

      ## Examples

        iex> User.errors_on(UserRecord.new(name: "Chris"), :name)
        ["name must be greater than 5 characters"]

        iex> User.errors_on(UserRecord.new(name: "Chris McCord"), :name)
        nil

      """
      def errors_on(record, attribute) do
        full_error_message(attribute, errors(record)[attribute])
      end

      defp full_error_message(attribute, error_body) do
        "#{attribute} #{error_body}"
      end

      def valid?(record) do
        record |> errors |> Enum.empty?
      end

      def validations, do: @validations

      defp process_validation_form(record, {:presence_of, attribute, options}) do
        unless Present.present?(Record.get(record, attribute)) do
          {attribute, "must not be blank"}
        end
      end

      defp process_validation_form(record, {:format_of, attribute, options}) do

      end

      defp process_validation_form(record, {:length_of, attribute, options}) do
        length = Count.count(Record.get(record, attribute))
        
        error = case options do
          [within: from..to] when not(length >= from and length <= to) ->
            "between #{from} and #{to}"
          
          [greater_than: gt, less_than: lt] when not(length > gt and length < lt) ->
            "greater than #{gt} and less than #{lt}"
          
          [greater_than_or_equal: gte, less_than: lt] when not(length >= gte and length < lt) ->
            "greater than or equal to #{gte} and less than #{lt}"
          
          [greater_than: gt, less_than_or_equal: lte] when not(length > gt and length <= lte) ->
            "greater than #{gt} and less than or equal to #{lte}"
          
          [greater_than_or_equal: gte, less_than_or_equal: lte] when not(length >= gte and length <= lte) ->
            "greater than or equal to #{gte} and less than or equal to #{lte}"
          
          [greater_than: gt] when not(length > gt) ->
            "greater than #{gt}"
          
          [less_than: lt] when not(length < lt) ->
            "less than #{lt}"
          
          [less_than_or_equal: lte] when not(length <= lte) ->
            "less than or equal to #{lte}"
          
          [greater_than_or_equal: gte] when not(length >= gte) ->
            "greater than or equal to #{gte}"
          _ -> 
        end
        
        if error, do: {attribute, "must be #{error} characters" }
      end

      defp process_validation_form(record, {:numericality_of, attribute, options}) do
        unless valid_number?(Record.get(record, attribute)) do
          {attribute, "must be a valid number"}
        end
      end

      defp process_validation_form(record, {:custom, attribute, options}) do

      end
    end
  end

  defmacro validates_presence_of(attribute, options // []) do
    options = normalize_validation_options(options)
    quote do
      @validations {:presence_of, unquote(attribute), unquote(options)}
    end
  end

  defmacro validates_format_of(attribute, options // []) do
    options = normalize_validation_options(options)
    quote do
      @validations {:format_of, unquote(attribute), unquote(options)}
    end
  end

  defmacro validates_length_of(attribute, options // []) do
    options = normalize_validation_options(options)
    quote do
      @validations {:length_of, unquote(attribute), unquote(options)}
    end
  end

  defmacro validates_numericality_of(attribute, options // []) do
    options = normalize_validation_options(options)
    quote do
      @validations {:numericality_of, unquote(attribute), unquote(options)}
    end
  end

  defmacro validate(method_name, options // []) do
    options = normalize_validation_options(options)
    quote do
      @validations {:custom, unquote(method_name), unquote(options)}
    end
  end

  @doc """
  Sort validation options by key to allow pattern matching combinations
  """
  def normalize_validation_options(options), do: Enum.sort(options)
end


defrecord User, name: nil, city: nil

defmodule User do
  use Atlas.Model

  validates_presence_of :name
  validates_presence_of :city
  validates_length_of :name, within: 2..255
end
