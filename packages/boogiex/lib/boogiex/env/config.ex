defmodule Boogiex.Env.Config do
  alias Boogiex.Theory.Function

  @type t() :: [
          on_error: (term() -> any()),
          user_functions: MapSet.t({atom(), non_neg_integer()})
        ]

  @spec default() :: t()
  def default() do
    [on_error: fn _ -> nil end, user_functions: MapSet.new()]
  end

  @spec function(t(), atom(), non_neg_integer()) :: Function.t() | nil
  def function(config, name, arity) do
    if MapSet.member?(config[:user_functions], {name, arity}) do
      %Function{name: name}
    end
  end
end
