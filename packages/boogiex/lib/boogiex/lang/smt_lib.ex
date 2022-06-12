defmodule Boogiex.Lang.SmtLib do
  alias SmtLib.API
  alias SmtLib.Connection
  alias SmtLib.Syntax.From
  alias Boogiex.Error.SmtError

  @type context :: String.t() | (() -> String.t())

  @spec run(Connection.t(), context(), From.ast()) :: [term()]
  def run(conn, context, commands) do
    API.run(
      conn,
      From.commands(commands)
    )
    |> elem(1)
    |> List.wrap()
    |> Enum.map(fn
      :ok -> nil
      {:ok, r} -> r
      {:error, e} -> raise SmtError, error: e, context: from_context(context)
    end)
  end

  @spec from_context(context()) :: String.t()
  defp from_context(context) when is_bitstring(context) do
    context
  end

  defp from_context(context) when is_function(context) do
    context.()
  end
end
