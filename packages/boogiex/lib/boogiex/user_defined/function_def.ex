defmodule Boogiex.UserDefined.FunctionDef do
  alias Boogiex.Lang.L1Exp

  @type t() :: %__MODULE__{
          body: L1Exp.ast(),
          args: [L1Exp.ast()],
          guard: L1Exp.ast(),
          pre: L1Exp.ast(),
          post: L1Exp.ast()
        }
  defstruct [
    :body,
    :args,
    guard: true,
    pre: true,
    post: true
  ]
end
