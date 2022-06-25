defmodule Boogiex.Lang.SmtLib do
  alias SmtLib.API
  alias SmtLib.Connection
  alias SmtLib.Syntax.From
  alias Boogiex.Error.SmtError

  @type context :: String.t()
  @type connection :: Connection.t()

  @spec run(connection(), String.t(), From.ast()) :: [term()]
  def run(conn, context, commands) do
    API.run(
      conn,
      From.commands(commands)
      |> Code.eval_quoted()
      |> elem(0)
    )
    |> List.wrap()
    |> Enum.map(fn
      :ok -> nil
      {:ok, r} -> r
      {:error, e} -> raise SmtError, error: e, context: context
    end)
  end
end
