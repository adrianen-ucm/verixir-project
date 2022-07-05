defmodule Boogiex.Lang.L2Exp do
  require Logger
  alias Boogiex.Msg
  alias Boogiex.Lang.L1Exp
  alias Boogiex.Lang.L1Stm
  alias Boogiex.Lang.L2Var
  alias Boogiex.Lang.L2Match

  @type ast :: Macro.t()
  @type path_tree() ::
          {:end, L1Stm.ast(), L1Exp.ast()}
          | {:fork, L1Stm.ast(), path_tree(), Enumerable.t()}
          | {:extend, path_tree(), (L1Exp.ast() -> path_tree())}

  @spec translate(ast()) :: path_tree()
  def translate({:ghost, _, [[do: s]]}) do
    {:end, s, []}
  end

  def translate({:=, _, [p, e]}) do
    {
      :extend,
      translate(e),
      fn t ->
        {
          :end,
          quote do
            assert unquote(L2Match.translate(p, t)),
                   unquote(Msg.pattern_does_not_match(t, p))

            unquote_splicing(
              for var <- L2Var.vars(p) do
                quote do
                  havoc unquote(var)
                end
              end
            )

            assume unquote(t) === unquote(p),
                   unquote(Msg.pattern_does_not_match(t, p))
          end,
          t
        }
      end
    }
  end

  def translate({:__block__, _, []}) do
    {
      :end,
      quote do
      end,
      []
    }
  end

  def translate({:__block__, _, [e]}) do
    translate(e)
  end

  def translate({:__block__, mt, [h | t] = es}) do
    case List.pop_at(es, -1) do
      {{:ghost, _, [[do: s]]}, es} ->
        {
          :extend,
          translate({:__block__, mt, es}),
          fn t ->
            {
              :end,
              quote do
                (unquote_splicing([s] |> Enum.reject(&is_nil/1)))
              end,
              t
            }
          end
        }

      _ ->
        {
          :extend,
          translate(h),
          fn _ -> translate({:__block__, mt, t}) end
        }
    end
  end

  def translate({:if, _, [e, kw]}) do
    empty =
      quote do
      end

    translate(
      quote do
        case unquote(e) do
          true -> unquote(Keyword.get(kw, :do, empty))
          false -> unquote(Keyword.get(kw, :else, empty))
        end
      end
    )
  end

  def translate({:case, mt, [e, [do: bs]]}) do
    msg = Keyword.get(mt, :msg, Msg.no_case_pattern_holds_for(e))

    {
      :extend,
      translate(e),
      fn e_t ->
        {all_pattern_vars, one_pattern_holds} =
          Enum.reduce(bs, {MapSet.new(), false}, fn {:->, _, [[b], _]}, {vs, acc} ->
            {pi, fi} =
              case b do
                {:when, [], [pi, fi]} -> {pi, fi}
                pi -> {pi, true}
              end

            {
              MapSet.union(vs, L2Var.vars(pi)),
              quote(
                do:
                  unquote(acc) or
                    (unquote(L2Match.translate(pi, e_t)) and
                       (not (unquote(e_t) === unquote(pi)) or unquote(fi)))
              )
            }
          end)

        stms =
          Stream.transform(bs, true, fn {:->, _, [[b], ei]}, previous_do_not_hold ->
            {pi, fi} =
              case b do
                {:when, [], [pi, fi]} -> {pi, fi}
                pi -> {pi, true}
              end

            pattern_t = L2Match.translate(pi, e_t)

            {
              [
                {
                  :fork,
                  quote do
                    assume unquote(previous_do_not_hold),
                           unquote(Msg.bad_previous_branch_to(pi, fi))

                    assume unquote(pattern_t),
                           unquote(Msg.pattern_does_not_match(e_t, pi))

                    assume unquote(e_t) === unquote(pi),
                           unquote(Msg.pattern_does_not_match(e_t, pi))

                    assume unquote(fi),
                           unquote(Msg.guard_does_not_hold(fi))
                  end,
                  translate(ei),
                  []
                }
              ],
              quote(
                do:
                  unquote(previous_do_not_hold) and
                    not (unquote(pattern_t) and
                           (not (unquote(e_t) === unquote(pi)) or unquote(fi)))
              )
            }
          end)

        {
          :fork,
          quote do
            unquote_splicing(
              for var <- all_pattern_vars do
                quote do
                  havoc unquote(var)
                end
              end
            )

            assert unquote(one_pattern_holds),
                   unquote(msg)
          end,
          Enum.at(stms, 0),
          Stream.drop(stms, 1)
        }
      end
    }
  end

  def translate(e) do
    {
      :end,
      quote do
        assert is_tuple({unquote(e)})
      end,
      e
    }
  end
end
