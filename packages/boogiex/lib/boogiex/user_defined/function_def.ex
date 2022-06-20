defmodule Boogiex.UserDefined.FunctionDef do
  alias Boogiex.Lang.L1Exp
  alias Boogiex.Lang.L2Exp

  @type t() :: %__MODULE__{
          body: L2Exp.ast(),
          args: [L2Exp.ast()],
          pre: L1Exp.ast(),
          post: L1Exp.ast()
        }
  defstruct [
    :body,
    :args,
    pre: true,
    post: true
  ]
end
