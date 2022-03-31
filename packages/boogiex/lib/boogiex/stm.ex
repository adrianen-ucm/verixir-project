defmodule Boogiex.Stm do
  alias SmtLib.API
  alias Boogiex.Exp
  alias Boogiex.Env
  alias SmtLib.Syntax.From

  # TODO better error handling and pattern matching

  @spec havoc(Env.t(), Exp.ast()) :: :ok
  def havoc(env, ast) do
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

  @spec assume(Env.t(), Exp.ast()) :: :ok | {:error, :assume_failed}
  def assume(env, ast) do
    term = Exp.exp(env, ast)

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

    with {_, [:ok, :ok, {:ok, :unsat}, :ok]} <-
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
           ),
         # TODO short-circuit or always continue?
         {_, [:ok, :ok, {:ok, :unsat}, :ok, :ok]} <-
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
           ) do
      :ok
    else
      _ ->
        error = {:error, error_payload}
        Env.error(env, error)
        error
    end
  end
end
