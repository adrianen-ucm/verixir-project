defmodule Boogiex.Error.SmtError do
  @type t :: %__MODULE__{error: term()}
  defexception [:error]

  @spec message(t()) :: String.t()
  def message(smt_error) do
    "Runtime SMT error: #{inspect(smt_error.error)}"
  end
end
