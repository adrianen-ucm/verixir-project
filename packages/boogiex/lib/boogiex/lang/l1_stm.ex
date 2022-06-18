defmodule Boogiex.Lang.L1Stm do
  require Logger
  alias Boogiex.Msg
  alias Boogiex.Env
  alias Boogiex.Lang.L0Exp
  alias Boogiex.Lang.L1Exp
  alias Boogiex.Error.EnvError

  @type ast :: Macro.t()

  @spec eval(Env.t(), ast()) :: [term()]
  def eval(env, s) do
    Logger.debug(Macro.to_string(s), language: :l1)

    L0Exp.eval(
      env,
      fn -> Msg.evaluate_stm_context(s) end,
      translate(env, s)
    )
  end

  @spec translate(Env.t(), ast()) :: L0Exp.ast()
  def translate(_, {:havoc, _, [{var_name, _, _}]}) do
    quote do
      context unquote(fn -> Msg.havoc_context(var_name) end) do
        declare_const unquote(var_name)
      end
    end
  end

  def translate(env, {:assume, m, [f]}) do
    translate(env, {:assume, m, [f, Msg.assume_failed()]})
  end

  def translate(env, {:assume, _, [f, error]}) do
    {f_t, f_sem} = L1Exp.translate(env, f)

    quote do
      context unquote(Msg.assume_context(f)) do
        unquote_splicing([f_sem] |> Enum.reject(&is_nil/1))

        when_unsat add !:is_boolean.(unquote(f_t)) do
          add :boolean_val.(unquote(f_t))
        else
          fail unquote(error)
        end
      end
    end
  end

  def translate(env, {:assert, m, [f]}) do
    translate(env, {:assert, m, [f, Msg.assert_failed()]})
  end

  def translate(env, {:assert, _, [f, error]}) do
    {f_t, f_sem} = L1Exp.translate(env, f)

    quote do
      context unquote(Msg.assert_context(f)) do
        unquote_splicing([f_sem] |> Enum.reject(&is_nil/1))

        when_unsat add !:is_boolean.(unquote(f_t)) do
        else
          fail unquote(error)
        end

        when_unsat add !:boolean_val.(unquote(f_t)) do
          add :boolean_val.(unquote(f_t))
        else
          fail unquote(error)
        end
      end
    end
  end

  def translate(env, {:unfold, _, [{fun_name, _, args}]}) do
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

    quote do
      context unquote(Msg.unfold_context(fun_name, args, body.(args))) do
        unquote(
          translate(
            env,
            quote do
              assume unquote(fun_name)(unquote_splicing(args)) === unquote(body.(args)),
                     unquote(Msg.body_expansion_does_not_hold(fun_name, args))
            end
          )
        )

        unquote_splicing(
          for spec <- function.specs do
            {pre_t, pre_sem} = L1Exp.translate(env, spec.pre.(args))

            quote do
              unquote_splicing([pre_sem] |> Enum.reject(&is_nil/1))

              when_unsat add !:is_boolean.(unquote(pre_t)) do
                when_unsat add !:boolean_val.(unquote(pre_t)) do
                  unquote(
                    translate(
                      env,
                      quote do
                        assume unquote(spec.pre.(args)),
                               unquote(Msg.precondition_does_not_hold(fun_name, args))

                        assume unquote(spec.post.(args)),
                               unquote(Msg.postcondition_does_not_hold(fun_name, args))
                      end
                    )
                  )
                end
              end
            end
          end
        )
      end
    end
  end

  def translate(env, {:block, _, [[do: s]]}) do
    quote do
      context unquote(Msg.block_context()) do
        local do
          unquote(
            translate(
              env,
              s
            )
          )
        end
      end
    end
  end

  def translate(env, {:__block__, _, es}) do
    quote do
      (unquote_splicing(
         es
         |> Stream.map(&translate(env, &1))
         |> Enum.reject(&is_nil/1)
       ))
    end
  end
end
