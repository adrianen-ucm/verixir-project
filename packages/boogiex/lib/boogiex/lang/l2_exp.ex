defmodule Boogiex.Lang.L2Exp do
  require Logger
  alias Boogiex.Env
  alias Boogiex.Lang.L1Exp
  alias Boogiex.Lang.L1Stm

  @type ast :: Macro.t()

  # TODO use streams?
  # TODO try this and provide examples

  @spec validate(Env.t(), ast()) :: [term()]
  def validate(env, e) do
    Logger.debug(Macro.to_string(e), language: :l2)

    for {_, sem} <- translate(e) do
      L1Stm.eval(env, sem)
    end
    |> List.flatten()
  end

  @spec translate(ast()) :: [{L1Exp.ast(), L1Stm.ast()}]
  def translate({:ghost, _, [[do: s]]}) do
    [{nil, s}]
  end

  def translate({:=, _, [p, e]}) do
    for {t, sem} <- translate(e) do
      {
        t,
        quote do
          unquote(sem)

          assert unquote(translate_match(p, e))

          unquote(
            for var <- vars(p) do
              quote do
                havoc unquote(var)
              end
            end
          )

          assume unquote(t) === unquote(p)
        end
      }
    end
  end

  def translate(nil) do
    translate([])
  end

  def translate({:__block__, _, es}) do
    translate(es)
  end

  def translate([]) do
    [{nil, nil}]
  end

  def translate([h | t]) do
    for {_, h_sem} <- translate(h) do
      for {t_t, t_sem} <- translate(t) do
        {
          t_t,
          quote do
            unquote(h_sem)
            unquote(t_sem)
          end
        }
      end
    end
  end

  def translate({:case, _, [e, [do: bs]]}) do
    for {e_t, e_sem} <- translate(e) do
      # TODO more efficient
      one_pattern_holds =
        Enum.reduce(bs, false, fn {:->, _, [[b], _]}, acc ->
          {pi, fi} =
            case b do
              {:when, [], [pi, fi]} -> {pi, fi}
              pi -> {pi, true}
            end

          quote(
            do:
              unquote(acc) or
                (unquote(fi) and unquote(translate_match(pi, e_t)))
          )
        end)

      for {{:->, _, [[b], ei]}, i} <- Enum.with_index(bs) do
        {pi, fi} =
          case b do
            {:when, [], [pi, fi]} -> {pi, fi}
            pi -> {pi, true}
          end

        # TODO more efficient
        previous_do_not_hold =
          Enum.reduce(Enum.take(bs, i), true, fn {:->, _, [[b], _]}, acc ->
            {pi, fi} =
              case b do
                {:when, [], [pi, fi]} -> {pi, fi}
                pi -> {pi, true}
              end

            quote(
              do:
                unquote(acc) and
                  not (unquote(fi) and unquote(translate_match(pi, e_t)))
            )
          end)

        for {ei_t, ei_sem} <- Enum.with_index(translate(ei)) do
          {
            ei_t,
            quote do
              unquote(e_sem)

              assert unquote(one_pattern_holds)
              assume unquote(previous_do_not_hold)
              assume unquote(translate_match(pi, e_t)) and unquote(fi)

              unquote(
                for var <- vars(pi) do
                  quote do
                    havoc unquote(var)
                  end
                end
              )

              assume unquote(e_t) === unquote(pi)
              unquote(ei_sem)
            end
          }
        end
      end
    end
  end

  def translate(e) do
    [{e, nil}]
  end

  @spec translate_match(ast(), ast()) :: L1Exp.ast()
  defp translate_match(var, _) when is_atom(var) do
    true
  end

  defp translate_match([], e) do
    quote(do: unquote(e) === [])
  end

  defp translate_match([p1 | p2], e) do
    tr_1 = translate_match(p1, quote(do: hd(unquote(e))))
    tr_2 = translate_match(p2, quote(do: tl(unquote(e))))

    quote(
      do:
        is_list(unquote(e)) and unquote(e) !== [] and
          unquote(tr_1) and unquote(tr_2)
    )
  end

  defp translate_match(tup, e) when is_tuple(tup) do
    for i <- 1..tuple_size(tup) do
      translate_match(
        elem(tup, i - 1),
        quote(do: elem(unquote_splicing([e, i - 1])))
      )
    end
    |> Enum.reduce(
      quote(
        do:
          is_tuple(unquote(e)) and
            tuple_size(unquote(e)) === unquote(tuple_size(tup))
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

  @spec vars(ast()) :: MapSet.t(atom())
  defp vars(p) do
    Macro.prewalk(
      p,
      MapSet.new(),
      fn
        {var_name, _, m} = c, vs when is_atom(var_name) and is_atom(m) ->
          {c, MapSet.put(vs, var_name)}

        other_ast, other_acc ->
          {other_ast, other_acc}
      end
    )
    |> elem(1)
  end
end
