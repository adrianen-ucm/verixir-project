defmodule SmtLib.API do
  alias SmtLib.Syntax, as: S
  alias SmtLib.Connection, as: C

  @type state :: C.t() | {C.t(), result()}
  @type result ::
          :ok
          | {:ok, :sat | :unsat | :unknown}
          | {:error, term()}

  @spec run_commands(state(), [S.command_t()]) :: state()
  def run_commands(state, commands) do
    {connection, results} =
      case state do
        {connection, results} -> {connection, List.wrap(results)}
        connection -> {connection, []}
      end

    responses =
      commands
      |> Enum.map(&C.send_command(connection, &1))
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
