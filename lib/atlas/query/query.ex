defmodule Atlas.Query do
  defstruct model: nil, from: nil, wheres: [], select: nil, includes: [],
            joins: [], limit: nil, offset: nil, order_by: nil,
            order_by_direction: nil, count: false

  def new(attributes \\ []) when is_list(attributes) do
    struct(__MODULE__, attributes)
  end
  def new(map) when is_map(map) do
    new Map.to_list(map)
  end
end
