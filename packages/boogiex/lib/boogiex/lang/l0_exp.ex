defmodule Boogiex.Lang.L0Exp do
  require Logger
  alias Boogiex.Lang.SmtLib

  @type ast :: Macro.t()

  @spec eval(SmtLib.connection(), SmtLib.context(), ast()) :: [term()]
  def eval(conn, context, e) do
    Logger.debug(Macro.to_string(e), language: :l0)

    errors =
      eval_rec(conn, context, e)
      |> List.flatten()

    for e <- errors do
      Logger.error("Verification: #{e}", language: :l0)
    end

    errors
  end

  @spec eval_rec(SmtLib.connection(), SmtLib.context(), ast()) :: deep_error_list
        when deep_error_list: [term() | deep_error_list]
  defp eval_rec(_, _, {:fail, _, [error]}) do
    [error]
  end

  defp eval_rec(conn, context, {:add, _, [f]}) do
    SmtLib.run(conn, context, quote(do: assert(unquote(f))))
    []
  end

  defp eval_rec(conn, context, {:declare_const, _, [x]}) do
    SmtLib.run(conn, context, quote(do: declare_const([{unquote(x), Term}])))
    []
  end

  defp eval_rec(conn, context, {:local, _, [[do: e]]}) do
    SmtLib.run(conn, context, quote(do: push))
    errors = eval_rec(conn, context, e)
    SmtLib.run(conn, context, quote(do: pop))
    errors
  end

  defp eval_rec(conn, context, {:when_unsat, m, [e1, [do: e2]]}) do
    eval_rec(conn, context, {:when_unsat, m, [e1, [do: e2, else: nil]]})
  end

  defp eval_rec(conn, context, {:when_unsat, _, [e1, [do: e2, else: e3]]}) do
    SmtLib.run(conn, context, quote(do: push))
    errors = eval_rec(conn, context, e1)

    [result, nil] =
      SmtLib.run(
        conn,
        context,
        quote do
          check_sat
          pop
        end
      )

    [
      errors,
      case result do
        :unsat -> eval_rec(conn, context, e2)
        _ -> eval_rec(conn, context, e3)
      end
    ]
  end

  defp eval_rec(_, _, nil) do
    []
  end

  defp eval_rec(conn, context, {:__block__, _, es}) do
    Enum.map(es, &eval_rec(conn, context, &1))
  end

  defp eval_rec(conn, _, {:context, _, [context, [do: es]]}) do
    eval_rec(conn, context, es)
  end
end
