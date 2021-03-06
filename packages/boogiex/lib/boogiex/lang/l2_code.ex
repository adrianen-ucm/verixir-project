defmodule Boogiex.Lang.L2Code do
  require Logger
  alias Boogiex.Msg
  alias Boogiex.Env
  alias Boogiex.Lang.SmtLib
  alias Boogiex.Lang.L1Exp
  alias Boogiex.Lang.L1Stm
  alias Boogiex.Lang.L2Exp
  alias Boogiex.Lang.L2Var
  alias Boogiex.UserDefined
  alias Boogiex.Error.EnvError

  @spec verify(Env.t(), L2Exp.ast()) :: Enumerable.t()
  def verify(env, e) do
    Logger.debug(Macro.to_string(e), language: :l2)

    tuple_constructor = Env.tuple_constructor(env)

    SmtLib.run(
      Env.connection(env),
      Msg.block_context(),
      quote(do: push)
    )

    verify_rec(
      env,
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
      ),
      nil
    )

    SmtLib.run(
      Env.connection(env),
      Msg.block_context(),
      quote(do: pop)
    )

    Env.update_tuple_constructor(env, tuple_constructor)
  end

  @spec verify_rec(Env.t(), L2Exp.path_tree(), then) :: any()
        when then: nil | (L1Exp.ast() -> L2Exp.path_tree())
  def verify_rec(env, {:fork, s, c, cs}, then) do
    if Enum.empty?(cs) do
      L1Stm.eval(env, s)
      verify_rec(env, c, then)
    else
      L1Stm.eval(env, s)

      Enum.each(
        Enum.concat([c], cs),
        fn c ->
          tuple_constructor = Env.tuple_constructor(env)

          SmtLib.run(
            Env.connection(env),
            Msg.block_context(),
            quote(do: push)
          )

          verify_rec(env, c, then)

          SmtLib.run(
            Env.connection(env),
            Msg.block_context(),
            quote(do: pop)
          )

          Env.update_tuple_constructor(env, tuple_constructor)
        end
      )
    end
  end

  def verify_rec(env, {:extend, c, f}, nil) do
    verify_rec(env, c, f)
  end

  def verify_rec(env, {:extend, c, f}, then) do
    verify_rec(env, c, fn t ->
      {
        :extend,
        f.(t),
        then
      }
    end)
  end

  def verify_rec(env, {:end, s, t}, nil) do
    L1Stm.eval(env, s)

    L1Stm.eval(
      env,
      quote do
        assert is_tuple({unquote(t)})
      end
    )
  end

  def verify_rec(env, {:end, s, t}, then) do
    L1Stm.eval(env, s)
    verify_rec(env, then.(t), nil)
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

          {:case, [msg: Msg.no_precondition_holds(f, args)],
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

  def expand_specs({:=, mt, [p, e]}, user_defined) do
    {:=, mt, [p, expand_specs(e, user_defined)]}
  end

  def expand_specs({:__block__, mt, es}, user_defined) do
    {:__block__, mt, Enum.map(es, &expand_specs(&1, user_defined))}
  end

  def expand_specs({:case, mt, [e, [do: bs]]}, user_defined) do
    {:case, mt,
     [
       expand_specs(e, user_defined),
       [
         do:
           Enum.map(bs, fn {:->, mt, [[b], e]} ->
             {:->, mt, [[b], expand_specs(e, user_defined)]}
           end)
       ]
     ]}
  end

  def expand_specs({:if, mt, [e, kw]}, user_defined) do
    empty =
      quote do
      end

    {:if, mt,
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
              defs -> {ast, [{f, args, defs} | calls]}
            end

          other, calls ->
            {other, calls}
        end
      )

    quote do
      unquote_splicing(
        for {f, args, defs} <- calls do
          {:case, [msg: Msg.no_precondition_holds(f, args)],
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
