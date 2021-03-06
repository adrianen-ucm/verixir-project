defmodule Boogiex.Lang.L2Var do
  require Logger
  alias Boogiex.Msg
  alias Boogiex.Lang.L2Exp

  @typep ssa_state :: {
           %{atom() => non_neg_integer()},
           %{atom() => [non_neg_integer()]}
         }

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

  defp ssa_rec({:ghost, mt, [[do: s]]}, state) do
    {s, state} = ssa_rec(s, state)

    {
      {:ghost, mt, [[do: s]]},
      state
    }
  end

  defp ssa_rec({:havoc, mt, [{var_name, _, m} = var]}, state)
       when is_atom(var_name) and is_atom(m) do
    state = new_version_for_vars([var_name], state)
    {var, state} = ssa_rec(var, state)

    {
      {:havoc, mt, [var]},
      state
    }
  end

  defp ssa_rec({:__block__, mt, es}, state) do
    {es, state} = Enum.map_reduce(es, state, &ssa_rec/2)

    {
      {:__block__, mt, es},
      state
    }
  end

  defp ssa_rec({:=, mt, [p, e]}, state) do
    {e, state} = ssa_rec(e, state)
    state = new_version_for_vars(var_names(p), state)
    {p, state} = ssa_rec(p, state)

    {
      {:=, mt, [p, e]},
      state
    }
  end

  defp ssa_rec({:->, mt, [[b], e]}, state) do
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
      {:->, mt, [[{:when, [], [p, f]}], e]},
      {max_version, version_stack}
    }
  end

  defp ssa_rec({:case, mt, [e, [do: bs]]}, state) do
    {e, state} = ssa_rec(e, state)
    {bs, state} = Enum.map_reduce(bs, state, &ssa_rec/2)

    {
      {:case, mt, [e, [do: bs]]},
      state
    }
  end

  defp ssa_rec({:if, mt, [e, kw]}, state) do
    empty =
      quote do
      end

    {e, state} = ssa_rec(e, state)
    {e_do, state} = ssa_rec(Keyword.get(kw, :do, empty), state)
    {e_else, state} = ssa_rec(Keyword.get(kw, :else, empty), state)

    {
      {:if, mt, [e, [do: e_do, else: e_else]]},
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

  @spec var_names(L2Exp.ast()) :: MapSet.t(atom())
  def var_names(e) do
    MapSet.new(vars(e), &elem(&1, 0))
  end

  @spec vars(L2Exp.ast()) :: MapSet.t(L2Exp.ast())
  def vars(e) do
    Macro.prewalk(
      e,
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
