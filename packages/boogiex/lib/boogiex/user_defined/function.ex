defmodule Boogiex.UserDefined.Function do
  alias Boogiex.Lang.L1Exp
  alias Boogiex.UserDefined.Spec

  @type t() :: %__MODULE__{
          name: atom(),
          arity: non_neg_integer(),
          specs: [Spec.t()],
          body: nil | ([L1Exp.ast()] -> L1Exp.ast())
        }
  defstruct [:name, :arity, specs: [%Spec{}], body: nil]
end
