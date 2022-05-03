defmodule Boogiex.Theory.Function do
  alias Boogiex.Theory.Spec

  @type t() :: %__MODULE__{
          name: atom(),
          specs: [Spec.t()]
        }
  defstruct [:name, specs: [%Spec{}]]
end
