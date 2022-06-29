defmodule Boogiex.Lang.L2Exp do
  require Logger
  alias Boogiex.Msg
  alias Boogiex.Lang.L1Exp
  alias Boogiex.Lang.L1Stm
  alias Boogiex.Lang.L2Var
  alias Boogiex.Lang.L2Match

  @type ast :: Macro.t()
  @type path_tree() ::
          {:leaf, L1Stm.ast(), L1Exp.ast()}
          | {:node, L1Stm.ast(), path_tree(), Enumerable.t()}

  @spec translate(ast()) :: path_tree()
  def translate({:ghost, _, [[do: s]]}) do
    {:leaf, s, []}
  end

  def translate({:=, _, [p, e]}) do
    extend(
      translate(e),
      fn sem, t ->
        {
          :leaf,
          quote do
            unquote_splicing([sem] |> Enum.reject(&is_nil/1))

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
    )
  end

  def translate({:__block__, _, []}) do
    {
      :leaf,
      quote do
      end,
      []
    }
  end

  def translate({:__block__, _, [e]}) do
    translate(e)
  end

  def translate({:__block__, _, [h | t] = es}) do
    case List.pop_at(es, -1) do
      {{:ghost, _, [[do: s]]}, es} ->
        extend(
          translate({:__block__, [], es}),
          fn sem, t ->
            {
              :leaf,
              quote do
                (unquote_splicing([sem, s] |> Enum.reject(&is_nil/1)))
              end,
              t
            }
          end
        )

      _ ->
        extend(
          translate(h),
          fn h_sem, _ ->
            {
              :node,
              h_sem,
              translate({:__block__, [], t}),
              []
            }
          end
        )
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

  def translate({:case, _, [e, [do: bs]]}) do
    extend(
      translate(e),
      fn e_sem, e_t ->
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
                  :node,
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
          :node,
          quote do
            unquote_splicing([e_sem] |> Enum.reject(&is_nil/1))

            unquote_splicing(
              for var <- all_pattern_vars do
                quote do
                  havoc unquote(var)
                end
              end
            )

            assert unquote(one_pattern_holds),
                   unquote(Msg.no_case_pattern_holds_for(e))
          end,
          Enum.at(stms, 0),
          Stream.drop(stms, 1)
        }
      end
    )
  end

  def translate(e) do
    {
      :leaf,
      quote do
        assert is_tuple({unquote(e)})
      end,
      e
    }
  end

  @spec extend(path_tree(), (L1Stm.ast(), L1Exp.ast() -> path_tree())) :: path_tree()
  defp extend({:node, s, c, cs}, f) do
    {:node, s, extend(c, f), Stream.map(cs, &extend(&1, f))}
  end

  defp extend({:leaf, s, e}, f) do
    f.(s, e)
  end
end
