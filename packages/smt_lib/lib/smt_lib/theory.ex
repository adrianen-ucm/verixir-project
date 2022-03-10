defmodule SmtLib.Theory do
  @moduledoc """
  Shared utilities to define built-in SMT-LIB theories.
  """

  alias SmtLib.Syntax, as: S

  @doc """
  Defines an application term given a function identifier and two
  or more argument terms.

  Useful for function symbols annotated with :chainable, :left-assoc,
  :right-assoc or :pairwise.
  """
  @spec n_ary_app(S.identifier_t(), S.term_t(), S.term_t() | [S.term_t(), ...]) ::
          S.term_t()
  def n_ary_app(identifier, a, bs) when is_list(bs) do
    {:app, identifier, [a | bs]}
  end

  def n_ary_app(identifier, a, b) do
    {:app, identifier, [a, b]}
  end
end
