defmodule Boogiex.Lang.L2Exp do
  require Logger
  alias Boogiex.Msg
  alias Boogiex.Lang.L1Exp
  alias Boogiex.Lang.L1Stm
  alias Boogiex.Lang.L2Code

  @type ast :: Macro.t()
  @type enum(value) :: [value] | Enumerable.t()

  @spec translate(ast()) :: enum({L1Exp.ast(), L1Stm.ast()})
  def translate({:ghost, _, [[do: s]]}) do
    [{[], s}]
  end

  def translate({:=, _, [p, e]}) do
    Stream.map(translate(e), fn {t, sem} ->
      {
        t,
        quote do
          unquote_splicing([sem] |> Enum.reject(&is_nil/1))

          assert unquote(translate_match(p, e)),
                 unquote(Msg.pattern_does_not_match(e, p))

          unquote_splicing(
            for var <- L2Code.vars(p) do
              quote do
                havoc unquote(var)
              end
            end
          )

          assume unquote(t) === unquote(p),
                 unquote(Msg.pattern_does_not_match(e, p))
        end
      }
    end)
  end

  def translate({:__block__, _, []}) do
    [
      {[],
       quote do
       end}
    ]
  end

  def translate({:__block__, _, [e]}) do
    translate(e)
  end

  def translate({:__block__, _, [h | t] = es}) do
    case List.pop_at(es, -1) do
      {{:ghost, _, [[do: s]]}, es} ->
        Stream.map(translate({:__block__, [], es}), fn {es_t, es_sem} ->
          {
            es_t,
            quote do
              unquote_splicing([es_sem] |> Enum.reject(&is_nil/1))
              unquote_splicing([s] |> Enum.reject(&is_nil/1))
            end
          }
        end)

      {{:unfold, _, [{_, _, _}]} = ast, es} ->
        Stream.flat_map(translate(ast), fn {_, u_sem} ->
          Stream.map(translate({:__block__, [], es}), fn {es_t, es_sem} ->
            {
              es_t,
              quote do
                unquote_splicing([es_sem] |> Enum.reject(&is_nil/1))
                unquote_splicing([u_sem] |> Enum.reject(&is_nil/1))
              end
            }
          end)
        end)

      _ ->
        Stream.flat_map(translate(h), fn {_, h_sem} ->
          Stream.map(translate({:__block__, [], t}), fn {t_t, t_sem} ->
            {
              t_t,
              quote do
                unquote_splicing([h_sem] |> Enum.reject(&is_nil/1))
                unquote_splicing([t_sem] |> Enum.reject(&is_nil/1))
              end
            }
          end)
        end)
    end
  end

  def translate({:case, _, [e, [do: bs]]}) do
    Stream.flat_map(translate(e), fn {e_t, e_sem} ->
      {all_pattern_vars, one_pattern_holds} =
        Enum.reduce(bs, {MapSet.new(), false}, fn {:->, _, [[b], _]}, {vs, acc} ->
          {pi, fi} =
            case b do
              {:when, [], [pi, fi]} -> {pi, fi}
              pi -> {pi, true}
            end

          {
            MapSet.union(vs, L2Code.vars(pi)),
            quote(
              do:
                unquote(acc) or
                  (unquote(translate_match(pi, e_t)) and
                     (not (unquote(e_t) === unquote(pi)) or unquote(fi)))
            )
          }
        end)

      Stream.transform(bs, true, fn {:->, _, [[b], ei]}, previous_do_not_hold ->
        {pi, fi} =
          case b do
            {:when, [], [pi, fi]} -> {pi, fi}
            pi -> {pi, true}
          end

        pattern_t = translate_match(pi, e_t)

        {
          Stream.map(translate(ei), fn {ei_t, ei_sem} ->
            {
              ei_t,
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

                assume unquote(previous_do_not_hold),
                       unquote(Msg.bad_previous_branch_to(pi, fi))

                assume unquote(pattern_t) and (not (unquote(e_t) === unquote(pi)) or unquote(fi)),
                       unquote(Msg.pattern_does_not_match(e_t, pi))

                assume unquote(e_t) === unquote(pi),
                       unquote(Msg.pattern_does_not_match(e_t, pi))

                unquote_splicing([ei_sem] |> Enum.reject(&is_nil/1))
              end
            }
          end),
          quote(
            do:
              unquote(previous_do_not_hold) and
                not (unquote(pattern_t) and (not (unquote(e_t) === unquote(pi)) or unquote(fi)))
          )
        }
      end)
    end)
  end

  def translate(e) do
    [
      {e,
       quote do
         assert is_tuple({unquote(e)})
       end}
    ]
  end

  @spec translate_match(ast(), ast()) :: L1Exp.ast()
  defp translate_match({var_name, _, m}, _) when is_atom(var_name) and is_atom(m) do
    true
  end

  defp translate_match([{:|, _, [p1, p2]}], e) do
    tr_1 = translate_match(p1, quote(do: hd(unquote(e))))
    tr_2 = translate_match(p2, quote(do: tl(unquote(e))))

    quote(
      do:
        is_list(unquote(e)) and unquote(e) !== [] and
          unquote(tr_1) and unquote(tr_2)
    )
  end

  defp translate_match([], e) do
    quote(do: unquote(e) === [])
  end

  defp translate_match([p1 | p2], e) do
    translate_match([{:|, [], [p1, p2]}], e)
  end

  defp translate_match(tup, e) when is_tuple(tup) and tuple_size(tup) < 3 do
    translate_match({:{}, [], Tuple.to_list(tup)}, e)
  end

  defp translate_match({:{}, _, args}, e) do
    for {t, i} <- Enum.with_index(args) do
      translate_match(
        t,
        quote(do: elem(unquote_splicing([e, i])))
      )
    end
    |> Enum.reduce(
      quote(
        do:
          is_tuple(unquote(e)) and
            tuple_size(unquote(e)) === unquote(length(args))
      ),
      fn tr, acc ->
        quote do
          unquote(acc) and unquote(tr)
        end
      end
    )
  end

  defp translate_match(p, e) do
    quote(do: unquote(e) === unquote(p))
  end
end
