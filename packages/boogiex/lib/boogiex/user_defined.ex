defmodule Boogiex.UserDefined do
  alias Boogiex.UserDefined.Function

  @type functions :: %{{atom(), non_neg_integer()} => Function.t()}

  @type params :: [
          functions: functions()
        ]

  @opaque t() :: %__MODULE__{
            functions: functions()
          }
  defstruct [:functions]

  @spec new() :: t()
  @spec new(params()) :: t()
  def new(params \\ []) do
    Keyword.validate!(params, [:functions])
    {functions, []} = Keyword.pop(params, :functions, %{})

    %__MODULE__{
      functions: functions
    }
  end

  @spec functions(t()) :: [{atom(), non_neg_integer()}]
  def functions(user_defined) do
    Map.keys(user_defined.functions)
  end

  @spec function_defs(t(), atom(), non_neg_integer()) :: [Function.t()] | nil
  def function_defs(user_defined, name, arity) do
    Map.get(user_defined.functions, {name, arity})
  end
end
