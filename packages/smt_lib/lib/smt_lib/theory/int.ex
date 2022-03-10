defmodule SmtLib.Theory.Int do
  alias SmtLib.Syntax, as: S
  import SmtLib.Theory

  @spec sort() :: S.sort_t()
  def sort do
    {:sort, {:simple, "Int"}}
  end

  @spec numeral(S.numeral_t()) :: S.term_t()
  def numeral(n) do
    {:constant, {:numeral, n}}
  end

  @spec neg(S.term_t()) :: S.term_t()
  def neg(a) do
    {:app, {:simple, "-"}, [a]}
  end

  @spec add(S.term_t(), S.term_t() | [S.term_t(), ...]) :: S.term_t()
  def add(a, bs) do
    n_ary_app({:simple, "+"}, a, bs)
  end

  @spec sub(S.term_t(), S.term_t() | [S.term_t(), ...]) :: S.term_t()
  def sub(a, bs) do
    n_ary_app({:simple, "-"}, a, bs)
  end

  @spec mul(S.term_t(), S.term_t() | [S.term_t(), ...]) :: S.term_t()
  def mul(a, bs) do
    n_ary_app({:simple, "*"}, a, bs)
  end
end
