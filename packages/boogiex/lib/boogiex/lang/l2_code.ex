defmodule Boogiex.Lang.L2Code do
  require Logger
  alias Boogiex.Msg
  alias Boogiex.Env
  alias Boogiex.Lang.L1Stm
  alias Boogiex.Lang.L2Exp

  @typep ssa_state :: any()

  @spec verify(Env.t(), L2Exp.ast()) :: [term()]
  def verify(env, e) do
    Logger.debug(Macro.to_string(e), language: :l2)

    for {_, sem} <-
          L2Exp.translate(
            Env.user_defined(env),
            ssa(e)
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

  @spec ssa(L2Exp.ast()) :: L2Exp.ast()
  def ssa(e) do
    ssa_rec(e, {%{}, %{}}) |> elem(0)
  end

  @spec ssa_rec(L2Exp.ast(), ssa_state()) :: {L2Exp.ast(), ssa_state()}
  defp ssa_rec({var_name, _, m} = ast, {_, version_stack} = state)
       when is_atom(var_name) and is_atom(m) do
    case version_stack[var_name] do
      [h | _] ->
        {{h, [], nil}, state}

      _ ->
        Logger.warn(Msg.free_var_in_ssa(var_name))
        {ast, state}
    end
  end

  defp ssa_rec({:ghost, _, [[do: s]]}, state) do
    {s, state} = ssa_rec(s, state)

    {
      {:ghost, [], [[do: s]]},
      state
    }
  end

  defp ssa_rec({:__block__, _, es}, state) do
    {es, state} = Enum.map_reduce(es, state, &ssa_rec/2)

    {
      {:__block__, [], es},
      state
    }
  end

  defp ssa_rec({:=, _, [p, e]}, state) do
    {e, state} = ssa_rec(e, state)
    state = new_version_for_vars(var_names(p), state)
    {p, state} = ssa_rec(p, state)

    {
      {:=, [], [p, e]},
      state
    }
  end

  defp ssa_rec({:->, _, [[b], e]}, state) do
    {p, f} =
      case b do
        {:when, [], [p, f]} -> {p, f}
        p -> {p, true}
      end

    var_names = var_names(p)
    state = new_version_for_vars(var_names, state)
    {p, state} = ssa_rec(p, state)
    {f, state} = ssa_rec(f, state)
    {e, state} = ssa_rec(e, state)

    {max_version, version_stack} = state

    version_stack =
      Map.new(
        version_stack,
        fn
          {var, stack} ->
            if var in var_names do
              {var, tl(stack)}
            else
              {var, stack}
            end
        end
      )

    {
      {:->, [], [[{:when, [], [p, f]}], e]},
      {max_version, version_stack}
    }
  end

  defp ssa_rec({:case, _, [e, [do: bs]]}, state) do
    {e, state} = ssa_rec(e, state)
    {bs, state} = Enum.map_reduce(bs, state, &ssa_rec/2)

    {
      {:case, [], [e, [do: bs]]},
      state
    }
  end

  defp ssa_rec(e, state) do
    e =
      Macro.prewalk(
        e,
        fn
          {var_name, _, m} = var when is_atom(var_name) and is_atom(m) ->
            ssa_rec(var, state) |> elem(0)

          other ->
            other
        end
      )

    {e, state}
  end

  @spec remove_ghost(L2Exp.ast()) :: L2Exp.ast()
  def remove_ghost(ast) do
    Macro.prewalk(ast, fn
      {:__block__, meta, es} ->
        {:__block__, meta,
         Enum.reject(es, fn
           {:unfold, _, _} -> true
           {:ghost, _, _} -> true
           _ -> false
         end)}

      {:unfold, _, _} ->
        {:__block__, [], []}

      {:ghost, _, _} ->
        {:__block__, [], []}

      other ->
        other
    end)
  end

  @spec var_names(L2Exp.ast()) :: MapSet.t(atom())
  def var_names(p) do
    MapSet.new(vars(p), &elem(&1, 0))
  end

  @spec vars(L2Exp.ast()) :: MapSet.t(L2Exp.ast())
  def vars(p) do
    Macro.prewalk(
      p,
      MapSet.new(),
      fn
        {var_name, _, m} = c, vs when is_atom(var_name) and is_atom(m) ->
          {c, MapSet.put(vs, {var_name, [], nil})}

        other_ast, other_acc ->
          {other_ast, other_acc}
      end
    )
    |> elem(1)
  end

  @spec new_version_for_vars(Enumerable.t(), ssa_state()) :: ssa_state()
  defp new_version_for_vars(var_names, state) do
    Enum.reduce(
      var_names,
      state,
      fn var, {max_version, version_stack} ->
        {version, max_version} =
          Map.get_and_update(
            max_version,
            var,
            fn
              nil -> {1, 1}
              n -> {n + 1, n + 1}
            end
          )

        name = String.to_atom("#{var}_#{version}")

        version_stack =
          Map.update(
            version_stack,
            var,
            [name],
            fn ns -> [name | ns] end
          )

        {max_version, version_stack}
      end
    )
  end
end
