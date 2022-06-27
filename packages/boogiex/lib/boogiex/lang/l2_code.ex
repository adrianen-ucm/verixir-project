defmodule Boogiex.Lang.L2Code do
  require Logger
  alias Boogiex.Msg
  alias Boogiex.Env
  alias Boogiex.Lang.L1Stm
  alias Boogiex.Lang.L2Exp
  alias Boogiex.Lang.L2Var
  alias Boogiex.UserDefined
  alias Boogiex.Error.EnvError

  @spec verify(Env.t(), L2Exp.ast()) :: [term()]
  def verify(env, e) do
    Logger.debug(Macro.to_string(e), language: :l2)

    for {_, sem} <-
          L2Exp.translate(
            L2Var.ssa(
              expand_specs(
                expand_unfolds(
                  e,
                  Env.user_defined(env)
                ),
                Env.user_defined(env)
              )
            )
          ) do
      L1Stm.eval(
        env,
        quote do
          block do
            unquote(sem)
          end
        end
      )
    end
    |> List.flatten()
  end

  @spec remove_ghost(L2Exp.ast()) :: L2Exp.ast()
  def remove_ghost(ast) do
    Macro.prewalk(ast, fn
      {:__block__, meta, es} ->
        {:__block__, meta,
         Enum.reject(es, fn
           {:ghost, _, _} -> true
           {:unfold, _, _} -> true
           _ -> false
         end)}

      {:ghost, _, _} ->
        {:__block__, [], []}

      {:unfold, _, _} ->
        {:__block__, [], []}

      other ->
        other
    end)
  end

  @spec expand_unfolds(L2Exp.ast(), UserDefined.t()) :: L2Exp.ast()
  def expand_unfolds(ast, user_defined) do
    Macro.prewalk(
      ast,
      fn
        {:unfold, _, [{f, _, args}]} ->
          defs =
            with nil <- UserDefined.function_defs(user_defined, f, length(args)) do
              raise EnvError,
                message: Msg.undefined_user_defined_function(f, args)
            end

          {:case, [],
           [
             quote(do: {unquote_splicing(args)}),
             [
               do:
                 List.flatten(
                   for d <- defs do
                     quote do
                       {unquote_splicing(d.args)}
                       when unquote(d.pre) ->
                         res = unquote(d.body)

                         ghost do
                           assume res === unquote(f)(unquote_splicing(args))
                           assume unquote(d.post)
                         end
                     end
                   end
                 )
             ]
           ]}

        other ->
          other
      end
    )
  end

  @spec expand_specs(L2Exp.ast(), UserDefined.t()) :: L2Exp.ast()
  def expand_specs({:ghost, _, _} = ast, _) do
    ast
  end

  def expand_specs({:=, _, [p, e]}, user_defined) do
    {:=, [], [p, expand_specs(e, user_defined)]}
  end

  def expand_specs({:__block__, _, es}, user_defined) do
    {:__block__, [], Enum.map(es, &expand_specs(&1, user_defined))}
  end

  def expand_specs({:case, _, [e, [do: bs]]}, user_defined) do
    {:case, [],
     [
       expand_specs(e, user_defined),
       [
         do:
           Enum.map(bs, fn {:->, _, [[b], e]} ->
             {:->, [], [[b], expand_specs(e, user_defined)]}
           end)
       ]
     ]}
  end

  def expand_specs({:if, _, [e, kw]}, user_defined) do
    empty =
      quote do
      end

    {:if, [],
     [
       expand_specs(e, user_defined),
       [
         do: expand_specs(Keyword.get(kw, :do, empty), user_defined),
         else: expand_specs(Keyword.get(kw, :else, empty), user_defined)
       ]
     ]}
  end

  def expand_specs(e, user_defined) do
    {_, calls} =
      Macro.prewalk(
        e,
        [],
        fn
          {f, _, args} = ast, calls when is_list(args) ->
            case UserDefined.function_defs(user_defined, f, length(args)) do
              nil -> {ast, calls}
              defs -> {ast, [{defs, args} | calls]}
            end

          other, calls ->
            {other, calls}
        end
      )

    quote do
      unquote_splicing(
        for {defs, args} <- calls do
          {:case, [],
           [
             quote(do: {unquote_splicing(args)}),
             [
               do:
                 List.flatten(
                   for d <- defs do
                     quote do
                       {unquote_splicing(d.args)}
                       when unquote(d.pre) ->
                         ghost do
                           assume unquote(d.post)
                         end
                     end
                   end
                 )
             ]
           ]}
        end
      )

      unquote(e)
    end
  end
end
