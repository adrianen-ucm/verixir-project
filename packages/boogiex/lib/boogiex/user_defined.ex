defmodule Boogiex.UserDefined do
  alias Boogiex.UserDefined.Function

  @type params :: [
          on_error: (term() -> any()),
          functions: [Function.t()]
        ]

  @type t() :: %__MODULE__{
          on_error: (term() -> any()),
          functions: %{{atom(), non_neg_integer()} => Function.t()}
        }
  defstruct [:on_error, :functions]

  @spec new(params()) :: t()
  def new(params) do
    Keyword.validate!(params, [:on_error, :functions])
    {on_error, params} = Keyword.pop(params, :on_error, fn _ -> nil end)
    {functions, []} = Keyword.pop(params, :functions, [])

    %__MODULE__{
      on_error: on_error,
      functions:
        functions
        |> Enum.map(&{{&1.name, &1.arity}, &1})
        |> Map.new()
    }
  end

  @spec functions(t()) :: [{atom(), non_neg_integer()}]
  def functions(user_defined) do
    Map.keys(user_defined.functions)
  end

  @spec function(t(), atom(), non_neg_integer()) :: Function.t() | nil
  def function(user_defined, name, arity) do
    Map.get(user_defined.functions, {name, arity})
  end
end
