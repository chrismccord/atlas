defmodule Atlas.Validator do

  defmacro __using__(_options) do
    quote do
      @message_prefix_delimiter "_"
      Module.register_attribute __MODULE__, :validations, accumulate: true,
                                                          persist: false
      import unquote(__MODULE__)
      alias Atlas.Present
      alias Atlas.Count
      alias Atlas.Record
      @before_compile unquote(__MODULE__)
    end
  end

  def valid_number?(number) when is_number(number), do: true
  def valid_number?(value) when is_binary(value) do
    Regex.match?(%r/^(-)?[0-9]+(\.[0-9]+)?$/, value)
  end
  def valid_number?(_), do: false

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

  defmacro validates_inclusion_of(attribute, options // []) do
    options = normalize_validation_options(options)
    quote do
      @validations {:inclusion_of, unquote(attribute), unquote(options)}
    end
  end

  defmacro validates(method_name, options // []) do
    options = normalize_validation_options(options)
    quote do
      @validations {:custom, unquote(method_name), unquote(options)}
    end
  end

  @doc """
  Sort validation options by key to allow pattern matching combinations
  """
  def normalize_validation_options(options), do: Enum.sort(options)

  defmacro __before_compile__(_env) do
    quote do

      def validations, do: @validations

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

      defp full_error_message(attribute, nil), do: nil
      defp full_error_message(attribute, error_body) do
        if include_attribute_prefix_in_error?(error_body) do
          "#{attribute}#{exclude_attribute_prefix(error_body)}"
        else
          error_body
        end
      end

      defp exclude_attribute_prefix(message) do
        String.replace message, @message_prefix_delimiter, "", global: false
      end

      defp include_attribute_prefix_in_error?(message) do
        String.starts_with? message, @message_prefix_delimiter
      end

      def valid?(record) do
        record |> errors |> Enum.empty?
      end

      defp process_validation_form(record, {:presence_of, attribute, options}) do
        value   = Record.get(record, attribute)
        message = Keyword.get options, :message, "_ must not be blank"

        unless Present.present?(value), do: {attribute, message}
      end

      defp process_validation_form(record, {:format_of, attribute, options}) do
        value   = to_binary(Record.get(record, attribute))
        regexp  = Keyword.get options, :with
        message = Keyword.get options, :message, "_ is not valid"

        unless Regex.match?(regexp, value), do: {attribute, message}
      end

      defp process_validation_form(record, {:inclusion_of, attribute, options}) do
        value   = to_binary(Record.get(record, attribute))
        in_list = Keyword.get(options, :in, []) |> Enum.map to_binary(&1)
        message = Keyword.get options, :message, "_ must be one of #{Enum.join in_list, ", "}"

        unless Enum.member?(in_list, value), do: {attribute, message}
      end

      defp process_validation_form(record, {:length_of, attribute, options}) do
        length  = Count.count(Record.get(record, attribute))
        message = Keyword.get options, :message
        options = Keyword.delete options, :message
        within  = Keyword.get options, :within

        default_error = case options do
          [within: from..to] when not(length >= from and length <= to) ->
            "_ must be between #{from} and #{to} characters"

          [greater_than: gt, less_than: lt] when not(length > gt and length < lt) ->
            "_ must be greater than #{gt} and less than #{lt} characters"

          [greater_than_or_equal: gte, less_than: lt] when not(length >= gte and length < lt) ->
            "_ must be greater than or equal to #{gte} and less than #{lt} characters"

          [greater_than: gt, less_than_or_equal: lte] when not(length > gt and length <= lte) ->
            "_ must be greater than #{gt} and less than or equal to #{lte} characters"

          [greater_than_or_equal: gte, less_than_or_equal: lte] when not(length >= gte and length <= lte) ->
            "_ must be greater than or equal to #{gte} and less than or equal to #{lte} characters"

          [greater_than: gt] when not(length > gt) ->
            "_ must be greater than #{gt} characters"

          [less_than: lt] when not(length < lt) ->
            "_ must be less than #{lt} characters"

          [less_than_or_equal: lte] when not(length <= lte) ->
            "_ must be less than or equal to #{lte} characters"

          [greater_than_or_equal: gte] when not(length >= gte) ->
            "_ must be greater than or equal to #{gte} characters"
          _->
        end

        if default_error, do: {attribute, message || default_error}
      end

      defp process_validation_form(record, {:numericality_of, attribute, options}) do
        value   = Record.get(record, attribute)
        message = Keyword.get options, :message, "_ must be a valid number"

        unless valid_number?(value), do: {attribute, message}
      end

      defp process_validation_form(record, {:custom, method_name, options}) do
        apply __MODULE__, method_name, [record]
      end
    end
  end
end