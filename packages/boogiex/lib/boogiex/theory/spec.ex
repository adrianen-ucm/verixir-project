defmodule Boogiex.Theory.Spec do
  @type t() :: %__MODULE__{
          pre: ([Macro.t()] -> Macro.t()),
          post: ([Macro.t()] -> Macro.t())
        }
  defstruct [:pre, :post]
end
