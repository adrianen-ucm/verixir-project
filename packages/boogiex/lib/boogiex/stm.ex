defmodule Boogiex.Stm do
  alias SmtLib.API
  alias Boogiex.Exp
  alias Boogiex.Env
  alias SmtLib.Syntax.From
  alias Boogiex.Error.SmtError

  # TODO refactor error handling in stm and exp
  @spec havoc(Env.t(), Exp.ast()) :: :ok | {:error, term()}
  def havoc(env, ast) do
    term = Exp.exp(env, ast)

    {_, declare_result} =
      API.run(
        Env.connection(env),
        From.commands(
          quote do
            declare_const [{unquote(term), Term}]
          end
        )
      )

    with {:error, e} <- declare_result do
      raise SmtError, error: e
    end
  end

  @spec assume(Env.t(), Exp.ast()) :: :ok | {:error, term()}
  def assume(env, ast) do
    term = Exp.exp(env, ast)

    {_, [push_result, assert_result_1, sat_result, pop_result, assert_result_2]} =
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

    sat_result =
      with :ok <- push_result,
           :ok <- assert_result_1,
           {:ok, sat_result} <- sat_result,
           :ok <- pop_result,
           :ok <- assert_result_2 do
        sat_result
      else
        {:error, e} -> raise SmtError, error: e
      end

    case sat_result do
      :unsat ->
        :ok

      _ ->
        Env.error(env, :assume_failed)
        {:error, :assume_failed}
    end
  end

  @spec assert(Env.t(), Exp.ast(), term()) :: :ok | {:error, term()}
  def assert(env, ast, error_payload) do
    term = Exp.exp(env, ast)

    {_, [push_result, assert_result, sat_result_1, pop_result]} =
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

    sat_result_1 =
      with :ok <- push_result,
           :ok <- assert_result,
           {:ok, sat_result_1} <- sat_result_1,
           :ok <- pop_result do
        sat_result_1
      else
        {:error, e} -> raise SmtError, error: e
      end

    {_, [push_result, assert_result_1, sat_result_2, pop_result, assert_result_2]} =
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

    sat_result_2 =
      with :ok <- push_result,
           :ok <- assert_result_1,
           {:ok, sat_result_2} <- sat_result_2,
           :ok <- pop_result,
           :ok <- assert_result_2 do
        sat_result_2
      else
        {:error, e} -> raise SmtError, error: e
      end

    case {sat_result_1, sat_result_2} do
      {:unsat, :unsat} ->
        :ok

      _ ->
        Env.error(env, error_payload)
        {:error, error_payload}
    end
  end
end
