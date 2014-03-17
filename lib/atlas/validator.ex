defmodule Atlas.Validator do
  import Atlas.FieldConverter

  alias Atlas.Present
  alias Atlas.Count
  alias Atlas.Record

  @moduledoc """
  Provides Model validations including validation rule definitions and error messages.

  # Validation types

    ## validates_presence_of
      Uses Atlas.Present protocol to ensure field is non-blank value

    ## validates_format_of
      Validates if field matches format given by regular expression

      options
        `with: [regex]`

    ## validates_inclusion_of
      Validates if field is included in list of values

      options
        `in: [list]`

    ## validates_length_of
      Validates if length of string is within min and maxima

      options
        `within: [number]`
        `greater_than: [number]`
        `greater_than_or_equal: [number]`
        `less_than: [number]`
        `less_than_or_equal: [number]`


    ## validates_numericality_of
      Validates that given string value is a valid number

    ## validates
      Provides custom validation functions. First argument is atom of function name to be
      called.


  # Custom validations
    Custom validations can be used to define arbitrary functions to call when validating
    a model. The functions return a tuple containing the field name and error message if
    an object is found to be invalid, nil otherwise.


  # Error message formatting
    When providing custom error messages to valdations, with `message:`, an underscore
    can be used to substitute the field name within the error message.


  Examples

    defmodule User do
      use Atlas.Model

      field :id,    :integer
      field :email, :string
      field :age,   :integer
      field :state, :string

      validates_numericality_of :id
      validates_presence_of :email
      validates_length_of :email, within: 5..255
      validates_length_of :state, greater_than_or_equal: 2, less_than_or_equal: 255
      validates_format_of :email, with: %r/.*@.*/, message: "Email must be valid"
      validates_inclusion_of :age, in: [10, 11, 12]

      validates :lives_in_ohio

      def lives_in_ohio(record) do
        unless record.state == "OH", do: {:state, "_ must be in Ohio"}
      end
    end

    ```
    iex> user = User.Record.new(email: "invalid")
    User.Record[id: nil, email: "invalid"...

    iex> User.valid? user
    false

    iex> User.full_error_messages user
    ["email must be between 5 and 255 characters","email must not be blank","id must be a valid number"]

    iex> User.errors_on(user, :id)
    ["id must be a valid number"]
    ```
  """

  defmacro __using__(_options) do
    quote do
      @message_prefix_delimiter "_"
      Module.register_attribute __MODULE__, :validations, accumulate: true,
                                                          persist: false
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  def valid_number?(number) when is_number(number), do: true
  def valid_number?(value) when is_binary(value) do
    Regex.match?(%r/^(-)?[0-9]+(\.[0-9]+)?$/, value)
  end
  def valid_number?(_), do: false

  defmacro validates_presence_of(attribute, options \\ []) do
    options = normalize_validation_options(options)
    quote do
      @validations {:presence_of, unquote(attribute), unquote(options)}
    end
  end

  defmacro validates_format_of(attribute, options \\ []) do
    options = normalize_validation_options(options)
    quote do
      @validations {:format_of, unquote(attribute), unquote(options)}
    end
  end

  defmacro validates_length_of(attribute, options \\ []) do
    options = normalize_validation_options(options)
    quote do
      @validations {:length_of, unquote(attribute), unquote(options)}
    end
  end

  defmacro validates_numericality_of(attribute, options \\ []) do
    options = normalize_validation_options(options)
    quote do
      @validations {:numericality_of, unquote(attribute), unquote(options)}
    end
  end

  defmacro validates_inclusion_of(attribute, options \\ []) do
    options = normalize_validation_options(options)
    quote do
      @validations {:inclusion_of, unquote(attribute), unquote(options)}
    end
  end

  defmacro validates(method_name, options \\ []) do
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

      def __atlas__(:validations), do: @validations

      def validate(record) do
        case errors(record) do
          []      -> {:ok, record}
          errors  -> {:error, record, errors}
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
        |> Enum.map(&process_validation_form(record, &1))
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
        record
        |> errors
        |> Keyword.get_values(attribute)
        |> Enum.map(&full_error_message(attribute, &1))
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

      # def valid?(record) do
      #   record |> errors |> Enum.empty?
      # end

      defp process_validation_form(record, {:presence_of, attribute, options}) do
        value   = Record.get(record, attribute)
        message = Keyword.get options, :message, "_ must not be blank"

        unless Present.present?(value), do: {attribute, message}
      end

      defp process_validation_form(record, {:format_of, attribute, options}) do
        value   = to_string(Record.get(record, attribute))
        regexp  = Keyword.get options, :with
        message = Keyword.get options, :message, "_ is not valid"

        unless Regex.match?(regexp, value), do: {attribute, message}
      end

      defp process_validation_form(record, {:inclusion_of, attribute, options}) do
        value   = to_string(Record.get(record, attribute))
        in_list = Keyword.get(options, :in, []) |> Enum.map &to_string(&1)
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
        value   = value_to_field_type(Record.get(record, attribute), :float)
        message = Keyword.get options, :message
        options = Keyword.delete options, :message
        within  = Keyword.get options, :within

        if !valid_number?(value) do
          {attribute, message ||  "_ must be a valid number"}
        else
          default_error = case options do
            [within: from..to] when not(value >= from and value <= to) ->
              "_ must be between #{from} and #{to}"

            [greater_than: gt, less_than: lt] when not(value > gt and value < lt) ->
              "_ must be greater than #{gt} and less than #{lt}"

            [greater_than_or_equal: gte, less_than: lt] when not(value >= gte and value < lt) ->
              "_ must be greater than or equal to #{gte} and less than #{lt}"

            [greater_than: gt, less_than_or_equal: lte] when not(value > gt and value <= lte) ->
              "_ must be greater than #{gt} and less than or equal to #{lte}"

            [greater_than_or_equal: gte, less_than_or_equal: lte] when not(value >= gte and value <= lte) ->
              "_ must be greater than or equal to #{gte} and less than or equal to #{lte}"

            [greater_than: gt] when not(value > gt) ->
              "_ must be greater than #{gt}"

            [less_than: lt] when not(value < lt) ->
              "_ must be less than #{lt}"

            [less_than_or_equal: lte] when not(value <= lte) ->
              "_ must be less than or equal to #{lte}"

            [greater_than_or_equal: gte] when not(value >= gte) ->
              "_ must be greater than or equal to #{gte}"
            _->
          end

          if default_error, do: {attribute, message || default_error}
        end
      end

      defp process_validation_form(record, {:custom, method_name, options}) do
        apply __MODULE__, method_name, [record]
      end
    end
  end
end
