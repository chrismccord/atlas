defexception Atlas.Exceptions.UndefinedRelationship,
             message: "Undefined model relationship",
             can_retry: false do

  def full_message(me) do
    "Call failed: #{me.message}, retriable: #{me.can_retry}"
  end
end