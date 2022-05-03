defmodule Boogiex.Theory.Spec do
  alias Boogiex.Trivial
  alias SmtLib.Syntax.From

  @type t() :: %__MODULE__{
          pre: ([From.ast()] -> From.ast()),
          post: ([From.ast()] -> From.ast())
        }
  defstruct pre: &Trivial.trivial/1,
            post: &Trivial.trivial/1
end
