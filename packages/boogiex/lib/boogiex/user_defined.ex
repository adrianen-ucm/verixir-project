defmodule Boogiex.UserDefined do
  alias Boogiex.UserDefined.Function

  @type params :: [
          functions: [Function.t()]
        ]

  @type t() :: %__MODULE__{
          functions: %{{atom(), non_neg_integer()} => Function.t()}
        }
  defstruct [:functions]

  @spec new() :: t()
  @spec new(params()) :: t()
  def new(params \\ []) do
    Keyword.validate!(params, [:functions])
    {functions, []} = Keyword.pop(params, :functions, [])

    %__MODULE__{
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
