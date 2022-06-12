defmodule SmtLib.API do
  @moduledoc """
  An API for running SMT-LIB commands as specified in `SmtLib.Syntax`.
  """

  require Logger
  alias SmtLib.Syntax, as: S
  alias SmtLib.Connection, as: C

  @typedoc """
  A state intended to be chained between `run/2` calls. It can be
  either an `SmtLib.Connection` or a tuple with an `SmtLib.Connection`
  and either a single `result` or a non empty list of them.
  """
  @type state :: C.t() | {C.t(), result() | [result(), ...]}

  @typedoc """
  The result of `run/2`.
  """
  @type result ::
          :ok
          | {:ok, :sat | :unsat | :unknown}
          | {:error, term()}

  @doc """
  Runs the given SMT-LIB commands as specified in `SmtLib.Syntax` and returns an
  `state` with the result or results.

  It also requires a `state` which can be just an `SmtLib.Connection` or the `state`
  produced by a previous `run/2` call. In this later case, the final `state` contains
  also the result of the previous one.
  """
  @spec run(state(), [S.command_t()]) :: state()
  def run(state, commands) do
    {connection, results} =
      case state do
        {connection, results} -> {connection, List.wrap(results)}
        connection -> {connection, []}
      end

    responses =
      commands
      |> Enum.map(fn c ->
        Logger.debug(SmtLib.String.From.command(c), language: :smtlib)
        C.send_command(connection, c)
      end)
      |> Enum.map(fn r ->
        with :ok <- r,
             {:ok, r} <- C.receive_response(connection) do
          case r do
            :success -> :ok
            {:specific_success_response, {:check_sat_response, r}} -> {:ok, r}
            {:error, r} -> {:error, r}
            other -> {:error, other}
          end
        end
      end)

    case results ++ responses do
      [result] -> {connection, result}
      results -> {connection, results}
    end
  end

  @doc """
  Takes a `state`, closes its underlying `SmtLib.Connection` and returns
  the results.
  """
  @spec close(state()) :: result()
  def close({connection, results}) do
    C.close(connection)
    results
  end

  def close(connection) do
    C.close(connection)
    :ok
  end
end
