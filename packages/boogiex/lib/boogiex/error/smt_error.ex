defmodule Boogiex.Error.SmtError do
  @type t :: %__MODULE__{error: term(), context: String.t()}
  defexception [:error, :context]

  @spec message(t()) :: String.t()
  def message(smt_error) do
    """
    Runtime SMT error when #{smt_error.context}:

    #{case smt_error.error do
      string when is_bitstring(string) -> string
      other -> inspect(other)
    end}
    """
  end
end
