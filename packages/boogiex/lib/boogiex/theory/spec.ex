defmodule Boogiex.Theory.Spec do
  alias SmtLib.Syntax.From

  @type t() :: %__MODULE__{
          pre: ([From.ast()] -> From.ast()),
          post: ([From.ast()] -> From.ast())
        }
  defstruct [:pre, :post]
end
