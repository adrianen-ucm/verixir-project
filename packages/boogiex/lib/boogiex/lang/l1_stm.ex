defmodule Boogiex.Lang.L1Stm do
  alias Boogiex.Msg
  alias Boogiex.Env
  alias Boogiex.Lang.L0Exp
  alias Boogiex.Lang.L1Exp
  alias Boogiex.Error.EnvError

  @spec havoc(Env.t(), L1Exp.ast()) :: :ok | {:error, [term()]}
  def havoc(env, {var_name, _, _}) do
    errors =
      L0Exp.eval(
        Env.connection(env),
        fn -> Msg.havoc_context(var_name) end,
        quote do
          declare_const unquote(var_name)
        end
      )

    to_result(env, errors)
  end

  @spec assume(Env.t(), L1Exp.ast(), term()) :: :ok | {:error, [term()]}
  def assume(env, ast, error) do
    {term, t_errors} = L1Exp.eval(env, ast)

    errors =
      L0Exp.eval(
        Env.connection(env),
        fn -> Msg.assume_context(ast) end,
        quote do
          when_unsat add !:is_boolean.(unquote(term)) do
            add :boolean_val.(unquote(term))
          else
            fail unquote(error)
          end
        end
      )

    to_result(env, [t_errors, errors])
  end

  @spec assert(Env.t(), L1Exp.ast(), term()) :: :ok | {:error, [term()]}
  def assert(env, ast, error) do
    {term, t_errors} = L1Exp.eval(env, ast)

    errors =
      L0Exp.eval(
        Env.connection(env),
        fn -> Msg.assert_context(ast) end,
        quote do
          when_unsat add !:is_boolean.(unquote(term)) do
          else
            fail unquote(error)
          end

          when_unsat add !:boolean_val.(unquote(term)) do
            add :boolean_val.(unquote(term))
          else
            fail unquote(error)
          end
        end
      )

    to_result(env, [t_errors, errors])
  end

  @spec unfold(Env.t(), atom(), [L1Exp.ast()]) :: :ok | {:error, [term()]}
  def unfold(env, fun_name, args) do
    function =
      with nil <- Env.user_function(env, fun_name, length(args)) do
        raise EnvError,
          message: Msg.undefined_function(fun_name, args)
      end

    body =
      with nil <- function.body do
        raise EnvError,
          message: Msg.undefined_function_body(fun_name, args)
      end

    body_errors =
      assume(
        env,
        quote(do: unquote(fun_name)(unquote_splicing(args)) === unquote(body.(args))),
        Msg.body_expansion_does_not_hold(fun_name, args)
      )
      |> to_errors()

    specs_errors =
      for spec <- function.specs do
        {pre_t, pre_errors} = L1Exp.eval(env, spec.pre.(args))

        assert_pre_errors =
          L0Exp.eval(
            Env.connection(env),
            fn -> Msg.unfold_context(fun_name, args, body.(args)) end,
            quote do
              when_unsat add !:is_boolean.(unquote(pre_t)) do
                when_unsat add !:boolean_val.(unquote(pre_t)) do
                else
                  fail nil
                end
              else
                fail nil
              end
            end
          )

        if Enum.empty?(assert_pre_errors) do
          assume_pre_errors =
            assume(
              env,
              spec.pre.(args),
              Msg.precondition_does_not_hold(fun_name, args)
            )
            |> to_errors()

          assume_post_errors =
            assume(
              env,
              spec.post.(args),
              Msg.postcondition_does_not_hold(fun_name, args)
            )
            |> to_errors()

          [pre_errors, assume_pre_errors, assume_post_errors]
        else
          [pre_errors]
        end
      end

    to_result(env, [body_errors, specs_errors])
  end

  @spec to_result(Env.t(), [term()]) :: :ok | {:error, deep_error_list}
        when deep_error_list: [term() | deep_error_list]
  defp to_result(env, errors) do
    case List.flatten(errors) do
      [] ->
        :ok

      errors ->
        Env.error(env, errors)
        {:error, errors}
    end
  end

  defp to_errors(result) do
    case result do
      :ok ->
        []

      {:error, errors} ->
        errors
    end
  end
end
