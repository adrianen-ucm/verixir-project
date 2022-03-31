defmodule SmtLib do
  @moduledoc """
  A high level API for running SMT-LIB commands written in a DSL.

  This is just `SmtLib.API` but with a DSL flavour using macros.
  """

  alias SmtLib.API
  alias SmtLib.Syntax.From
  alias SmtLib.Connection.Z3, as: Default

  @type state :: Macro.t()

  @doc """
  Runs SMT-LIB commands written in Elixir syntax as specified in
  `SmtLib.Syntax.From` and returns the result or results.

  For more details about the return value, this function is syntactic sugar for
  `SmtLib.API.run/2`.

  ## Examples

      iex> run do
      ...>   declare_sort Man
      ...>   declare_fun mortal: Man :: Bool
      ...>   assert forall :mortal.(:x), x: Man
      ...>   declare_const socrates: Man
      ...>   assert !:mortal.(:socrates)
      ...>   check_sat
      ...> end |> close()
      [:ok, :ok, :ok, :ok, :ok, {:ok, :unsat}]

  The `SmtLib.Connection` can be explicitly provided:

      iex> conn = SmtLib.Connection.Z3.new(timeout: 500)
      iex> {conn, :ok} = run conn, declare_const x: Bool
      iex> close(conn)
      :ok

  Several runs can be chained and their results are accumulated:

      iex> run do
      ...>   declare_const x: Bool
      ...>   assert :x || !:x
      ...> end
      ...> |> run(check_sat)
      ...> |> close()
      [:ok, :ok, {:ok, :sat}]

  """
  @spec run(From.ast()) :: Macro.t()
  @spec run(state(), From.ast()) :: Macro.t()
  defmacro run(state \\ default_state(), ast) do
    quote do
      API.run(
        unquote(state),
        unquote(
          ast
          |> From.commands()
          |> Macro.escape()
        )
      )
    end
  end

  @doc """
  Closes an `SmtLib.Connection` and, when chained at the end of a
  `SmtLib.run/2` examples, it forwards the results.

  See its usage in the `SmtLib.run/2` examples. This function is a
  counterpart for `SmtLib.API.close/1`.
  """
  @spec close(state()) :: Macro.t()
  defmacro close(state) do
    quote do
      API.close(unquote(state))
    end
  end

  @spec default_state() :: state()
  defp default_state() do
    quote do
      Default.new()
    end
  end
end
