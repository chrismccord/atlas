defmodule Atlas.Record do

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
    lc {key, _} inlist record.__record__(:fields) do
      { key, get(record, key) }
    end
  end
end
