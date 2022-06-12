defmodule Boogiex.BuiltIn.Spec do
  alias SmtLib.Syntax.From

  @type t() :: %__MODULE__{
          pre: ([From.ast()] -> From.ast()),
          post: ([From.ast()] -> From.ast())
        }
  defstruct pre: &__MODULE__.trivial/1,
            post: &__MODULE__.trivial/1

  @spec trivial(any) :: true
  def trivial(_) do
    true
  end
end
