defmodule Boogiex.Stm do
  alias SmtLib.API
  alias Boogiex.Exp
  alias Boogiex.Env
  alias SmtLib.Syntax.From

  # TODO transform unmatched patterns into error data?
  # I'm going to annotate errors which maybe should be reported

  @spec havoc(Env.t(), Exp.ast()) :: :ok | {:error, term()}
  def havoc(env, ast) do
    # TODO exp can report error
    term = Exp.exp(env, ast)

    {_, :ok} =
      API.run(
        Env.connection(env),
        From.commands(
          quote do
            declare_const [{unquote(term), Term}]
          end
        )
      )

    :ok
  end

  @spec assume(Env.t(), Exp.ast()) :: :ok | {:error, term()}
  def assume(env, ast) do
    term = Exp.exp(env, ast)

    # TODO maybe the asserts :ok are errors
    {_, [:ok, :ok, {:ok, result}, :ok, :ok]} =
      API.run(
        Env.connection(env),
        From.commands(
          quote do
            push
            assert !:is_boolean.(unquote(term))
            check_sat
            pop
            assert :boolean_val.(unquote(term))
          end
        )
      )

    case result do
      :unsat ->
        :ok

      _ ->
        error = {:error, :assume_failed}
        Env.error(env, error)
        error
    end
  end

  @spec assert(Env.t(), Exp.ast(), term()) :: :ok | {:error, term()}
  def assert(env, ast, error_payload) do
    term = Exp.exp(env, ast)

    # TODO maybe the assert :ok are errors
    {_, [:ok, :ok, {:ok, result1}, :ok]} =
      API.run(
        Env.connection(env),
        From.commands(
          quote do
            push
            assert !:is_boolean.(unquote(term))
            check_sat
            pop
          end
        )
      )

    # TODO maybe the asserts :ok are errors
    {_, [:ok, :ok, {:ok, result2}, :ok, :ok]} =
      API.run(
        Env.connection(env),
        From.commands(
          quote do
            push
            assert !:boolean_val.(unquote(term))
            check_sat
            pop
            assert :boolean_val.(unquote(term))
          end
        )
      )

    case {result1, result2} do
      {:unsat, :unsat} ->
        :ok

      _ ->
        error = {:error, error_payload}
        Env.error(env, error)
        error
    end
  end
end
