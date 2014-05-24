defmodule Atlas.Record do

  @reserved_fields [:model, :__preloaded__]

  @doc """
  Returns the attribute of the record given the key
  """
  def get(record, key) do
    apply(elem(record, 0), key, [record])
  end

  @doc """
  Converts a record into a keyword list
  """
  def to_list(record) do
    for {key, _} <- record.__record__(:fields), !Enum.member?(@reserved_fields, key) do
      { key, get(record, key) }
    end
  end
end
