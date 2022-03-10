defmodule SmtLib do
  @moduledoc """
  A set of required functions that an SMT-LIB command binding should
  implement.

  The return types are not specified because the provided implementations
  take different approaches. See `SmtLib.Script` and `SmtLib.Session`.
  """

  alias SmtLib.Syntax, as: S

  @typedoc false
  @type implementation :: any()

  @callback assert(implementation(), S.term_t()) :: any()

  @callback check_sat(implementation()) :: any()

  @callback push(implementation(), S.numeral_t()) :: any()

  @callback pop(implementation(), S.numeral_t()) :: any()

  @callback declare_const(implementation(), S.symbol_t(), S.sort_t()) :: any()

  @callback declare_sort(implementation(), S.symbol_t(), S.numeral_t()) :: any()

  @callback declare_fun(implementation(), S.symbol_t(), [S.sort_t(), ...], S.sort_t()) :: any()
end
