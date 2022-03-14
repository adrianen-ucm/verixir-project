# TODO call this AST or rename dir structure to syntax

defmodule SmtLib.Syntax do
  @moduledoc """
  SMT-LIB syntax as type definitions.
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
end
