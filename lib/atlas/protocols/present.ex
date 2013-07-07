defprotocol Atlas.Present do
  def present?(data)
end

defimpl Atlas.Present, for: Number do
  def present?(_), do: true
end

defimpl Atlas.Present, for: List do
  def present?([]), do: false
  def present?(_),  do: true
end

defimpl Atlas.Present, for: Atom do
  def present?(false), do: false
  def present?(nil),   do: false
  def present?(_),     do: true
end

defimpl Atlas.Present, for: BitString do
  def present?(string), do: String.length(string) > 0
end
