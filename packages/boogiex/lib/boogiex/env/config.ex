defmodule Boogiex.Env.Config do
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

  @spec new(params()) :: Boogiex.Env.Config.t()
  def new(params) do
    %__MODULE__{
      on_error: Keyword.get(params, :on_error, fn _ -> nil end),
      user_functions:
        Map.new(
          for f <- Keyword.get(params, :user_functions, []) do
            {{f.name, f.arity}, f}
          end
        )
    }
  end

  @spec user_functions(t()) :: [{atom(), non_neg_integer()}]
  def user_functions(config) do
    Map.keys(config.user_functions)
  end

  @spec user_function(t(), atom(), non_neg_integer()) :: UserFunction.t() | nil
  def user_function(config, name, arity) do
    Map.get(config.user_functions, {name, arity})
  end
end
