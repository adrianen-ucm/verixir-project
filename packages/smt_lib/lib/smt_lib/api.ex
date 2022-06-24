defmodule SmtLib.API do
  @moduledoc """
  An API for running SMT-LIB commands as specified in `SmtLib.Syntax`.
  """

  require Logger
  alias SmtLib.Syntax, as: S
  alias SmtLib.Connection, as: C

  @typedoc """
  The result of `run/2`.
  """
  @type result ::
          :ok
          | {:ok, :sat | :unsat | :unknown}
          | {:error, term()}

  @spec run(C.t(), S.command_t() | [S.command_t()]) :: result() | [result()]
  def run(conn, commands) do
    responses =
      commands
      |> List.wrap()
      |> Enum.map(fn c ->
        Logger.debug(SmtLib.String.From.command(c), language: :smtlib)
        C.send_command(conn, c)
      end)
      |> Enum.map(fn r ->
        with :ok <- r,
             {:ok, r} <- C.receive_response(conn) do
          case r do
            :success ->
              :ok

            {:specific_success_response, {:check_sat_response, r}} ->
              Logger.debug("#{r}", language: :smtlib)
              {:ok, r}

            {:error, r} ->
              Logger.error("SMT-LIB #{r}", language: :smtlib)
              {:error, r}

            other ->
              Logger.error("SMT-LIB #{other}", language: :smtlib)
              {:error, other}
          end
        end
      end)

    case responses do
      [result] -> result
      results -> results
    end
  end

  @spec close(C.t()) :: :ok | {:error, term()}
  def close(connection) do
    C.close(connection)
  end
end
