defmodule SmtLib.Theory.Bool do
  alias SmtLib.Syntax, as: S
  import SmtLib.Theory

  @spec sort() :: S.sort_t()
  def sort do
    {:sort, {:simple, "Bool"}}
  end

  @spec bool(boolean()) :: S.term_t()
  def bool(true) do
    {:identifier, {:simple, "true"}}
  end

  def bool(false) do
    {:identifier, {:simple, "false"}}
  end

  @spec neg(S.term_t()) :: S.term_t()
  def neg(a) do
    {:app, {:simple, "not"}, [a]}
  end

  @spec eq(S.term_t(), S.term_t() | [S.term_t(), ...]) :: S.term_t()
  def eq(a, bs) do
    n_ary_app({:simple, "="}, a, bs)
  end

  @spec impl(S.term_t(), S.term_t() | [S.term_t(), ...]) :: S.term_t()
  def impl(a, bs) do
    n_ary_app({:simple, "=>"}, a, bs)
  end

  @spec conj(S.term_t(), S.term_t() | [S.term_t(), ...]) :: S.term_t()
  def conj(a, bs) do
    n_ary_app({:simple, "and"}, a, bs)
  end

  @spec disj(S.term_t(), S.term_t() | [S.term_t(), ...]) :: S.term_t()
  def disj(a, bs) do
    n_ary_app({:simple, "or"}, a, bs)
  end

  @spec forall(
          S.sorted_var_t() | [S.sorted_var_t(), ...],
          (S.term_t() | [S.term_t(), ...] -> S.term_t())
        ) :: S.term_t()
  def forall({v, _} = a, p) do
    {:forall, [a], p.({:identifier, {:simple, v}})}
  end

  def forall(as, p) do
    {:forall, as,
     p.(
       Enum.map(as, fn {s, _} ->
         {:identifier, {:simple, s}}
       end)
     )}
  end
end
