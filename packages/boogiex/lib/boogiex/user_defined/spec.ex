defmodule Boogiex.UserDefined.Spec do
  alias Boogiex.Lang.L1Exp

  @type t() :: %__MODULE__{
          pre: ([L1Exp.ast()] -> L1Exp.ast()),
          post: ([L1Exp.ast()] -> L1Exp.ast())
        }
  defstruct pre: &__MODULE__.trivial/1,
            post: &__MODULE__.trivial/1

  @spec trivial(any) :: true
  def trivial(_) do
    true
  end
end
