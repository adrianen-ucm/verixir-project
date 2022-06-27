defmodule Boogiex.Lang.L2Match do
  alias Boogiex.Lang.L1Exp
  alias Boogiex.Lang.L2Exp

  @type ast :: Macro.t()

  @spec translate(ast(), L2Exp.ast()) :: L1Exp.ast()
  def translate({var_name, _, m}, _) when is_atom(var_name) and is_atom(m) do
    true
  end

  def translate([{:|, _, [p1, p2]}], e) do
    tr_1 = translate(p1, quote(do: hd(unquote(e))))
    tr_2 = translate(p2, quote(do: tl(unquote(e))))

    quote(
      do:
        is_list(unquote(e)) and unquote(e) !== [] and
          unquote(tr_1) and unquote(tr_2)
    )
  end

  def translate([], e) do
    quote(do: unquote(e) === [])
  end

  def translate([p1 | p2], e) do
    translate([{:|, [], [p1, p2]}], e)
  end

  def translate(tup, e) when is_tuple(tup) and tuple_size(tup) < 3 do
    translate({:{}, [], Tuple.to_list(tup)}, e)
  end

  def translate({:{}, _, args}, e) do
    Enum.reduce(
      Enum.with_index(args),
      quote(
        do:
          is_tuple(unquote(e)) and
            tuple_size(unquote(e)) === unquote(length(args))
      ),
      fn {t, i}, acc ->
        quote do
          unquote(acc) and
            unquote(
              translate(
                t,
                quote(do: elem(unquote(e), unquote(i)))
              )
            )
        end
      end
    )
  end

  def translate(p, e) do
    quote(do: unquote(e) === unquote(p))
  end
end
