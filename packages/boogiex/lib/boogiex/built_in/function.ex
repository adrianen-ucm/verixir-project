defmodule Boogiex.BuiltIn.Function do
  alias Boogiex.BuiltIn.Spec

  @type t() :: %__MODULE__{
          name: atom(),
          specs: [Spec.t()]
        }
  defstruct [:name, specs: [%Spec{}]]
end
