defmodule SmtLib do
  @moduledoc """
  A high level API for running SMT-LIB commands written in a DSL.
  """

  import SmtLib.Syntax.From

  @spec run(Macro.t(), Macro.t()) :: Macro.t()
  defmacro run(state \\ default_state(), ast) do
    commands =
      List.flatten(
        case ast do
          [do: {:__block__, _, asts}] -> Enum.map(asts, &command(&1))
          ast -> [command(ast)]
        end
      )

    quote do
      {connection, results} =
        case unquote(state) do
          {connection, results} -> {connection, List.wrap(results)}
          connection -> {connection, []}
        end

      responses =
        unquote(commands)
        |> Enum.map(&SmtLib.Connection.send_command(connection, &1))
        |> Enum.map(fn r ->
          with :ok <- r,
               {:ok, r} <- SmtLib.Connection.receive_response(connection) do
            case r do
              :success -> :ok
              {:specific_success_response, {:check_sat_response, r}} -> {:ok, r}
              other -> {:error, r}
            end
          end
        end)

      case results ++ responses do
        [result] -> {connection, result}
        results -> {connection, results}
      end
    end
  end

  @spec close(Macro.t()) :: Macro.t()
  defmacro close(state) do
    quote do
      case unquote(state) do
        {connection, results} ->
          SmtLib.Connection.close(connection)
          results

        connection ->
          SmtLib.Connection.close(connection)
          :ok
      end
    end
  end

  @spec default_state() :: Macro.t()
  defp default_state() do
    quote do
      SmtLib.Connection.Z3.new()
    end
  end
end
