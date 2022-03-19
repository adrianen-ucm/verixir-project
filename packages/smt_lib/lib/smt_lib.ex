defmodule SmtLib do
  @moduledoc """
  A high level API for running SMT-LIB commands written in a DSL.
  """

  alias SmtLib.Syntax.From

  @spec run(Macro.t()) :: Macro.t()
  @spec run(Macro.t(), Macro.t()) :: Macro.t()
  defmacro run(state \\ default_state(), ast) do
    quote do
      SmtLib.API.run_commands(
        unquote(state),
        unquote(
          ast
          |> From.commands()
          |> Macro.escape()
        )
      )
    end
  end

  @spec close(Macro.t()) :: Macro.t()
  defmacro close(state) do
    quote do
      SmtLib.API.close(unquote(state))
    end
  end

  @spec default_state() :: Macro.t()
  defp default_state() do
    quote do
      SmtLib.Connection.Z3.new()
    end
  end
end
