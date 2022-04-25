defmodule Boogiex.Env.UserEnv do
  alias Boogiex.Env.UserFunction

  @type params :: [
          on_error: (term() -> any()),
          user_functions: [UserFunction.t()]
        ]

  @type t() :: %__MODULE__{
          on_error: (term() -> any()),
          user_functions: %{{atom(), non_neg_integer()} => UserFunction.t()}
        }
  defstruct [:on_error, :user_functions]

  @spec new(params()) :: t()
  def new(params) do
    Keyword.validate!(params, [:on_error, :user_functions])
    {on_error, params} = Keyword.pop(params, :on_error, fn _ -> nil end)
    {user_functions, []} = Keyword.pop(params, :user_functions, [])

    %__MODULE__{
      on_error: on_error,
      user_functions:
        user_functions
        |> Enum.map(&{{&1.name, &1.arity}, &1})
        |> Map.new()
    }
  end

  @spec user_functions(t()) :: [{atom(), non_neg_integer()}]
  def user_functions(user_env) do
    Map.keys(user_env.user_functions)
  end

  @spec user_function(t(), atom(), non_neg_integer()) :: UserFunction.t() | nil
  def user_function(user_env, name, arity) do
    Map.get(user_env.user_functions, {name, arity})
  end
end
