defmodule SmtLib.Syntax do
  @moduledoc """
  SMT-LIB syntax specified as Elixir terms, and some utilities to manage them.
  """

  @type symbol_t :: atom()
  @type string_t :: String.t()
  @type numeral_t :: non_neg_integer()

  @type constant_t ::
          {:string, string_t()}
          | {:numeral, numeral_t()}

  @type identifier_t ::
          {:simple, symbol_t()}

  @type sort_t ::
          {:sort, identifier_t()}
          | {:app, identifier_t(), [sort_t(), ...]}

  @type sorted_var_t :: {symbol_t(), sort_t()}

  @type term_t ::
          {:constant, constant_t()}
          | {:identifier, identifier_t()}
          | {:app, identifier_t(), [term_t(), ...]}
          | {:forall, [sorted_var_t(), ...], term_t()}

  @type command_t ::
          {:assert, term_t()}
          | :check_sat
          | {:push, numeral_t()}
          | {:pop, numeral_t()}
          | {:declare_const, symbol_t(), sort_t()}
          | {:declare_sort, symbol_t(), numeral_t()}
          | {:declare_fun, symbol_t(), [sort_t()], sort_t()}
          | {:define_fun, symbol_t(), [sorted_var_t()], sort_t(), term_t()}

  @type check_sat_response_t ::
          :sat
          | :unsat
          | :unknown

  @type specific_success_response_t ::
          {:check_sat_response, check_sat_response_t()}

  @type general_response_t ::
          :success
          | :unsupported
          | {:error, string_t()}
          | {:specific_success_response, specific_success_response_t()}

  @doc """
  Returns a `MapSet` with the constant subterms of a given term.

  ## Example

  The following example uses also the module `SmtLib.Syntax.From`
  in order to write the SMT-LIB term in Elixir syntax:

      iex> SmtLib.Syntax.term_constants(
      ...>   SmtLib.Syntax.From.term(quote do
      ...>     forall :x * :x * :x == (1 + 2) * :x,
      ...>       x: Bool
      ...>     end
      ...>   )
      ...> )
      MapSet.new([{:numeral, 1}, {:numeral, 2}])

  """
  @spec term_constants(term_t()) :: MapSet.t(constant_t())
  def term_constants(term) do
    term_constants_rec(term, MapSet.new())
  end

  @spec term_constants_rec(term_t(), MapSet.t(constant_t())) :: MapSet.t(constant_t())
  defp term_constants_rec(term, terms) do
    case term do
      {:constant, c} -> MapSet.put(terms, c)
      {:identifier, _} -> terms
      {:app, _, args} -> Enum.reduce(args, terms, &term_constants_rec(&1, &2))
      {:forall, _, term} -> term_constants_rec(term, terms)
    end
  end
end
