defmodule Boogiex.Lang.L0Exp do
  require Logger
  alias Boogiex.Msg
  alias Boogiex.Lang.SmtLib

  @type ast :: Macro.t()
  @typep deep_error_list :: [term() | deep_error_list()]

  @spec eval(SmtLib.connection(), Msg.t(), ast()) :: [term()]
  def eval(conn, context, e) do
    Logger.debug(Macro.to_string(e), language: :l0)

    errors =
      eval_rec(conn, context, e, [])
      |> List.flatten()

    for e <- errors do
      Logger.error("Verification: #{e}", language: :l0)
    end

    errors
  end

  @spec eval_rec(SmtLib.connection(), Msg.t(), ast(), deep_error_list()) ::
          deep_error_list()
  defp eval_rec(_, _, {:fail, _, [error]}, []) do
    [Msg.to_string(error)]
  end

  defp eval_rec(conn, context, {:fail, _, [_]} = ast, errors) do
    join(errors, eval_rec(conn, context, ast, []))
  end

  defp eval_rec(conn, context, {:add, _, [f]}, errors) do
    SmtLib.run(conn, context, quote(do: assert(unquote(f))))
    errors
  end

  defp eval_rec(conn, context, {:declare_const, _, [x]}, errors) do
    SmtLib.run(conn, context, quote(do: declare_const([{unquote(x), Term}])))
    errors
  end

  defp eval_rec(conn, context, {:local, _, [[do: e]]}, errors) do
    SmtLib.run(conn, context, quote(do: push))
    errors = eval_rec(conn, context, e, errors)
    SmtLib.run(conn, context, quote(do: pop))
    errors
  end

  defp eval_rec(conn, context, {:when_unsat, m, [e1, [do: e2]]}, errors) do
    eval_rec(conn, context, {:when_unsat, m, [e1, [do: e2, else: nil]]}, errors)
  end

  defp eval_rec(conn, context, {:when_unsat, _, [e1, [do: e2, else: e3]]}, errors) do
    SmtLib.run(conn, context, quote(do: push))
    errors = eval_rec(conn, context, e1, errors)

    [result, nil] =
      SmtLib.run(
        conn,
        context,
        quote do
          check_sat
          pop
        end
      )

    case result do
      :unsat -> eval_rec(conn, context, e2, errors)
      _ -> eval_rec(conn, context, e3, errors)
    end
  end

  defp eval_rec(_, _, nil, errors) do
    errors
  end

  defp eval_rec(conn, context, {:__block__, _, es}, []) do
    Enum.flat_map(es, &eval_rec(conn, context, &1, []))
  end

  defp eval_rec(conn, context, {:__block__, _, _} = ast, errors) do
    join(errors, eval_rec(conn, context, ast, []))
  end

  defp eval_rec(conn, _, {:context, _, [context, [do: es]]}, errors) do
    eval_rec(conn, context, es, errors)
  end

  @spec join(deep_error_list(), deep_error_list()) :: deep_error_list()
  defp join([], []) do
    []
  end

  defp join([], es) do
    es
  end

  defp join(es, []) do
    es
  end

  defp join(es1, es2) do
    [es1, es2]
  end
end
