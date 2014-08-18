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
  def count(atom), do: atom |> Atom.to_string |> String.length
end

defimpl Atlas.Count, for: Map do
  def count(map), do: map_size(map)
end
