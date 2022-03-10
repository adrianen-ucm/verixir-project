defmodule SmtLib.String.To do
  alias SmtLib.Syntax, as: S
  alias SmtLib.String.To.Parsers, as: P

  @spec general_response(String.t()) :: {:ok, S.general_response_t()} | {:error, term()}
  def general_response(string) do
    string
    |> P.general_response()
    |> from_nimble()
  end

  defp from_nimble({:ok, [result], _, _, _, _}) do
    {:ok, result}
  end

  defp from_nimble({:ok, results, _, _, _, _}) do
    {:error, {:unexpected_parse_result, results}}
  end

  defp from_nimble({:error, reason, _, _, _, _}) do
    {:error, {:parse_error, reason}}
  end
end
