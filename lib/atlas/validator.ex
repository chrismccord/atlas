defmodule Atlas.Validator do

  def valid_number?(number) when is_number(number), do: true
  def valid_number?(value) when is_binary(value) do
    Regex.match?(%r/^(-)?[0-9]+(\.[0-9]+)?$/, value)
  end
  def valid_number?(_), do: false
end