defprotocol Atlas.Count do
  def count(data)
end

defimpl Atlas.Count, for: List do
  def count(list), do: Enum.count(list)
end

defimpl Atlas.Count, for: BitString do
  def count(string), do: String.length(string)
end

defimpl Atlas.Count, for: Atom do
  def count(nil), do: 0
  def count(atom), do: atom |> atom_to_binary |> String.length
end
