defmodule Boogiex.Stm do
  alias SmtLib.API
  alias Boogiex.Exp
  alias Boogiex.Env
  alias SmtLib.Syntax.From
  alias Boogiex.Error.SmtError

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
      raise SmtError,
        error: e,
        context: "declaring the variable #{Macro.to_string(ast)}"
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
        {:error, e} ->
          raise SmtError,
            error: e,
            context: "trying to assume #{Macro.to_string(ast)}"
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
        {:error, e} ->
          raise SmtError,
            error: e,
            context: "trying to assert #{Macro.to_string(ast)}"
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
        {:error, e} ->
          raise SmtError,
            error: e,
            context: "trying to assert #{Macro.to_string(ast)}"
      end

    case {sat_result_1, sat_result_2} do
      {:unsat, :unsat} ->
        :ok

      _ ->
        Env.error(env, error_payload)
        {:error, error_payload}
    end
  end

  @spec block(Env.t(), (() -> any())) :: any()
  def block(env, body) do
    {_, push_result} =
      API.run(
        Env.connection(env),
        From.commands(
          quote do
            push
          end
        )
      )

    with {:error, e} <- push_result do
      raise SmtError,
        error: e,
        context: "evaluating a block"
    end

    result = body.()

    {_, pop_result} =
      API.run(
        Env.connection(env),
        From.commands(
          quote do
            pop
          end
        )
      )

    with {:error, e} <- pop_result do
      raise SmtError,
        error: e,
        context: "evaluating a block"
    end

    result
  end

  @spec same(Env.t(), Exp.ast(), Exp.ast()) :: :ok | {:error, term()}
  def same(env, e1, e2) do
    t1 = Exp.exp(env, e1)
    t2 = Exp.exp(env, e2)

    {_, assert_result} =
      API.run(
        Env.connection(env),
        From.commands(
          quote do
            assert unquote(t1) == unquote(t2)
          end
        )
      )

    with {:error, e} <- assert_result do
      raise SmtError,
        error: e,
        context: "defining #{Macro.to_string(e2)} as #{Macro.to_string(e1)}"
    end
  end
end
