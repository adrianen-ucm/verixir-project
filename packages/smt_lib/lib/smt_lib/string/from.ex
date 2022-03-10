defmodule SmtLib.String.From do
  alias SmtLib.Syntax, as: S

  @spec command(S.command_t()) :: String.t()
  def command(c) do
    case c do
      {:assert, t} ->
        "(assert #{term(t)})"

      :check_sat ->
        "(check-sat)"

      {:push, n} ->
        "(push #{numeral(n)})"

      {:pop, n} ->
        "(pop #{numeral(n)})"

      {:declare_const, s1, s2} ->
        "(declare-const #{symbol(s1)} #{sort(s2)})"

      {:declare_sort, s, n} ->
        "(declare-sort #{symbol(s)} #{numeral(n)})"

      {:declare_fun, s1, ss, s2} ->
        arg_sorts = Enum.map_join(ss, " ", &sort/1)
        "(declare-fun #{symbol(s1)} (#{arg_sorts}) #{sort(s2)})"
    end
  end

  @spec term(S.term_t()) :: String.t()
  def term(t) do
    case t do
      {:constant, c} ->
        constant(c)

      {:identifier, i} ->
        identifier(i)

      {:app, i, ts} ->
        "(#{identifier(i)} #{Enum.map_join(ts, " ", &term/1)})"

      {:forall, sts, t} ->
        s_terms = Enum.map_join(sts, " ", &sorted_var/1)
        "(forall (#{s_terms}) #{term(t)})"
    end
  end

  @spec sort(S.sort_t()) :: String.t()
  def sort(s) do
    case s do
      {:sort, i} ->
        identifier(i)

      {:app, i, ss} ->
        "(#{identifier(i)} #{Enum.map_join(ss, " ", &sort/1)})"
    end
  end

  @spec sorted_var(S.sorted_var_t()) :: String.t()
  def sorted_var({s, st}) do
    "(#{symbol(s)} #{sort(st)})"
  end

  @spec identifier(S.identifier_t()) :: String.t()
  def identifier(i) do
    case i do
      {:simple, s} ->
        symbol(s)
    end
  end

  @spec constant(S.constant_t()) :: String.t()
  def constant(c) do
    case c do
      {:string, s} ->
        string(s)

      {:numeral, n} ->
        numeral(n)
    end
  end

  @spec numeral(S.numeral_t()) :: String.t()
  def numeral(n) do
    Integer.to_string(n)
  end

  @spec symbol(S.symbol_t()) :: String.t()
  def symbol(s) do
    s
  end

  @spec string(S.string_t()) :: String.t()
  def string(s) do
    "\"#{s}\""
  end
end
