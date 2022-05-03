defmodule Boogiex.Stm do
  alias SmtLib.API
  alias Boogiex.Exp
  alias Boogiex.Env
  alias SmtLib.Syntax.From
  alias Boogiex.Error.SmtError
  alias Boogiex.Error.EnvError

  @spec havoc(Env.t(), Exp.ast()) :: :ok | {:error, [term()]}
  def havoc(env, ast) do
    {term, errors} = Exp.exp(env, ast)

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

    case errors do
      [] ->
        :ok

      errors ->
        Env.error(env, errors)
        {:error, errors}
    end
  end

  @spec assume(Env.t(), Exp.ast(), term()) :: :ok | {:error, term()}
  def assume(env, ast, error_payload) do
    {term, errors} = Exp.exp(env, ast)

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

    errors =
      case sat_result do
        :unsat -> errors
        _ -> [error_payload | errors]
      end

    case errors do
      [] ->
        :ok

      errors ->
        Env.error(env, errors)
        {:error, errors}
    end
  end

  @spec assert(Env.t(), Exp.ast(), term()) :: :ok | {:error, term()}
  def assert(env, ast, error_payload) do
    {term, errors} = Exp.exp(env, ast)

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

    errors =
      case {sat_result_1, sat_result_2} do
        {:unsat, :unsat} -> errors
        _ -> [error_payload | errors]
      end

    case errors do
      [] ->
        :ok

      errors ->
        Env.error(env, errors)
        {:error, errors}
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

  @spec unfold(Env.t(), atom(), [Exp.ast()]) :: :ok | {:error, term()}
  def unfold(env, fun_name, args) do
    full_name = "#{Atom.to_string(fun_name)}/#{length(args)}"

    user_function =
      with nil <- Env.user_function(env, fun_name, length(args)) do
        raise EnvError,
          message: "Undefined user function #{full_name}"
      end

    {succeed, errors} =
      with nil <- user_function.body do
        {Enum.empty?(user_function.specs), []}
      else
        body ->
          result =
            assume(
              env,
              quote(do: unquote(fun_name)(unquote_splicing(args)) === unquote(body.(args))),
              "Assuming the #{full_name} body"
            )

          case result do
            :ok -> {true, []}
            {:error, e} -> {false, e}
          end
      end

    {succeed, errors} =
      user_function.specs
      |> Enum.reduce({succeed, errors}, fn spec, {succeed, errors} ->
        with :ok <-
               block(env, fn ->
                 assert(env, spec.pre.(args), nil)
               end) do
          result1 = assume(env, spec.pre.(args), "Assuming a #{full_name} precondition")
          result2 = assume(env, spec.post.(args), "Assuming a #{full_name} postcondition")

          errors =
            case result1 do
              :ok -> errors
              {:error, e} -> [e | errors]
            end

          errors =
            case result2 do
              :ok -> errors
              {:error, e} -> [e | errors]
            end

          case {result1, result2} do
            {:ok, :ok} -> {true, errors}
            _ -> {succeed, errors}
          end
        else
          {:error, _} -> {succeed, errors}
        end
      end)

    errors =
      if succeed do
        errors
      else
        ["No precondition for #{full_name} holds" | errors]
      end

    case List.flatten(errors) do
      [] ->
        :ok

      errors ->
        Env.error(env, errors)
        {:error, errors}
    end
  end
end
