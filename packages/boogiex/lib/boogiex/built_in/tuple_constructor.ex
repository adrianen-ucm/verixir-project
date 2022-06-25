defmodule Boogiex.BuiltIn.TupleConstructor do
  @opaque t :: %{non_neg_integer() => atom()}

  @spec new :: t()
  def new() do
    %{}
  end

  @spec get(t(), non_neg_integer()) :: {atom(), t()}
  def get(t, n) do
    Map.get_and_update(t, n, fn
      nil ->
        const = String.to_atom("tuple_#{n}")
        {const, const}

      const ->
        {const, const}
    end)
  end

  @spec get_all(t()) :: MapSet.t({non_neg_integer(), atom()})
  def get_all(t) do
    MapSet.new(t)
  end
end
