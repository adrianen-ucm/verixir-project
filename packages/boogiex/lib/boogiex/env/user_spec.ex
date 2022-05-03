defmodule Boogiex.Env.UserSpec do
  alias Boogiex.Exp
  alias Boogiex.Trivial

  @type t() :: %__MODULE__{
          pre: ([Exp.ast()] -> Exp.ast()),
          post: ([Exp.ast()] -> Exp.ast())
        }
  defstruct pre: &Trivial.trivial/1,
            post: &Trivial.trivial/1
end
