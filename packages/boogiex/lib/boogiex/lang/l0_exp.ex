defmodule Boogiex.Lang.L0Exp do
  require Logger
  alias Boogiex.Env
  alias Boogiex.Lang.SmtLib

  @type ast :: Macro.t()
  @type context :: String.t() | (() -> String.t())

  @spec eval(Env.t(), SmtLib.context(), ast()) :: [term()]
  def eval(env, context, e) do
    Logger.debug(Macro.to_string(e), language: :l0)
    eval_rec(env, context, e) |> List.flatten()
  end

  @spec eval_rec(Env.t(), SmtLib.context(), ast()) :: deep_error_list
        when deep_error_list: [term() | deep_error_list]
  defp eval_rec(_, _, {:fail, _, [error]}) do
    [error]
  end

  defp eval_rec(env, context, {:add, _, [f]}) do
    SmtLib.run(env, context, quote(do: assert(unquote(f))))
    []
  end

  defp eval_rec(env, context, {:declare_const, _, [x]}) do
    SmtLib.run(env, context, quote(do: declare_const([{unquote(x), Term}])))
    []
  end

  defp eval_rec(env, context, {:local, _, [[do: e]]}) do
    SmtLib.run(env, context, quote(do: push))
    Env.on_push(env)
    errors = eval_rec(env, context, e)
    SmtLib.run(env, context, quote(do: pop))
    Env.on_pop(env)
    errors
  end

  defp eval_rec(env, context, {:when_unsat, m, [e1, [do: e2]]}) do
    eval_rec(env, context, {:when_unsat, m, [e1, [do: e2, else: nil]]})
  end

  defp eval_rec(env, context, {:when_unsat, _, [e1, [do: e2, else: e3]]}) do
    SmtLib.run(env, context, quote(do: push))
    Env.on_push(env)
    errors = eval_rec(env, context, e1)

    [result, nil] =
      SmtLib.run(
        env,
        context,
        quote do
          check_sat
          pop
        end
      )

    Env.on_pop(env)

    [
      errors,
      case result do
        :unsat -> eval_rec(env, context, e2)
        _ -> eval_rec(env, context, e3)
      end
    ]
  end

  defp eval_rec(_, _, nil) do
    []
  end

  defp eval_rec(env, context, {:__block__, _, es}) do
    Enum.map(es, &eval_rec(env, context, &1))
  end

  defp eval_rec(env, _, {:context, _, [context, [do: es]]}) do
    eval_rec(env, context, es)
  end
end
