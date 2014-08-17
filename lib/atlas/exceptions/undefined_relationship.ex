defmodule Atlas.Exceptions.UndefinedRelationship do
  defexception [message: "Undefined model relationship",
                can_retry: false]

  def full_message(me) do
    "Call failed: #{me.message}, retriable: #{me.can_retry}"
  end
end
