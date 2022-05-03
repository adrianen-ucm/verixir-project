defmodule Boogiex.Env.UserFunction do
  alias Boogiex.Exp
  alias Boogiex.Env.UserSpec

  @type t() :: %__MODULE__{
          name: atom(),
          arity: non_neg_integer(),
          specs: [UserSpec.t()],
          body: nil | ([Exp.ast()] -> Exp.ast())
        }
  defstruct [:name, :arity, specs: [%UserSpec{}], body: nil]
end
