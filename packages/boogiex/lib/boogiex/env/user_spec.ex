defmodule Boogiex.Env.UserSpec do
  alias Boogiex.Exp

  @type t() :: %__MODULE__{
          pre: ([Exp.ast()] -> Exp.ast()),
          post: ([Exp.ast()] -> Exp.ast())
        }
  defstruct [:pre, :post]
end
