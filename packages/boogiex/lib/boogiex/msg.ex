defmodule Boogiex.Msg do
  @spec evaluate_stm_context(Macro.t()) :: String.t()
  def evaluate_stm_context(ast) do
    "evaluating statement #{Macro.to_string(ast)}"
  end

  @spec havoc_context(Macro.t()) :: String.t()
  def havoc_context(ast) do
    "declaring the variable #{Macro.to_string(ast)}"
  end

  @spec assume_context(Macro.t()) :: String.t()
  def assume_context(ast) do
    "trying to assume #{Macro.to_string(ast)}"
  end

  @spec assert_context(Macro.t()) :: String.t()
  def assert_context(ast) do
    "trying to assert #{Macro.to_string(ast)}"
  end

  @spec block_context() :: String.t()
  def block_context() do
    "evaluating a block"
  end

  @spec tuple_context([Macro.t()]) :: String.t()
  def tuple_context(args) do
    "processing the tuple with contents #{Macro.to_string(args)}"
  end

  @spec or_context(Macro.t(), Macro.t()) :: String.t()
  def or_context(e1, e2) do
    "processing #{Macro.to_string(e1)} or #{Macro.to_string(e2)}"
  end

  @spec and_context(Macro.t(), Macro.t()) :: String.t()
  def and_context(e1, e2) do
    "processing #{Macro.to_string(e1)} and #{Macro.to_string(e2)}"
  end

  @spec apply_context(Macro.t(), [Macro.t()]) :: String.t()
  def apply_context(f, args) do
    "processing #{Atom.to_string(f)}/#{length(args)}"
  end

  @spec unfold_context(Macro.t(), [Macro.t()], Macro.t()) :: String.t()
  def unfold_context(f, args, body) do
    "unfolding #{Atom.to_string(f)}/#{length(args)} into #{Macro.to_string(body)}"
  end

  @spec list_context(Macro.t(), Macro.t()) :: String.t()
  def list_context(h, t) do
    "processing the list with head #{Macro.to_string(h)} and tail #{Macro.to_string(t)}"
  end

  @spec literal_context(Macro.t()) :: String.t()
  def literal_context(ast) do
    "processing the literal #{Macro.to_string(ast)}"
  end

  @spec initialize_smt_context() :: String.t()
  def initialize_smt_context() do
    "executing the Boogiex SMT-LIB initialization code"
  end

  @spec initialize_user_defined_context() :: String.t()
  def initialize_user_defined_context() do
    "declaring the user defined functions"
  end

  @spec tuple_constructor_context(atom()) :: String.t()
  def tuple_constructor_context(name) do
    "declaring the tuple constructor #{name}"
  end

  @spec could_not_start_tuple_constructor(any()) :: String.t()
  def could_not_start_tuple_constructor(e) do
    "Could not start the tuple constructor agent: #{inspect(e)}"
  end

  @spec undefined_function_body(atom(), [Macro.t()]) :: String.t()
  def undefined_function_body(fun_name, args) do
    "Undefined body for user function #{Atom.to_string(fun_name)}/#{length(args)}"
  end

  @spec body_expansion_does_not_hold(atom(), [Macro.t()]) :: String.t()
  def body_expansion_does_not_hold(fun_name, args) do
    "#{Atom.to_string(fun_name)}/#{length(args)} body expansion does not hold"
  end

  @spec precondition_does_not_hold(atom(), [Macro.t()]) :: String.t()
  def precondition_does_not_hold(fun_name, args) do
    "A #{Atom.to_string(fun_name)}/#{length(args)} precondition does not hold"
  end

  @spec postcondition_does_not_hold(atom(), [Macro.t()]) :: String.t()
  def postcondition_does_not_hold(fun_name, args) do
    "A #{Atom.to_string(fun_name)}/#{length(args)} postcondition does not hold"
  end

  @spec no_precondition_holds(atom(), [Macro.t()]) :: String.t()
  def no_precondition_holds(fun_name, args) do
    "No precondition for #{Atom.to_string(fun_name)}/#{length(args)} holds"
  end

  @spec not_boolean(Macro.t()) :: String.t()
  def not_boolean(ast) do
    "#{Macro.to_string(ast)} is not boolean"
  end

  @spec undefined_function(atom(), [Macro.t()]) :: String.t()
  def undefined_function(fun_name, args) do
    "Undefined function #{Atom.to_string(fun_name)}/#{length(args)}"
  end

  @spec unknown_literal_type(Macro.t()) :: String.t()
  def unknown_literal_type(literal) do
    "Unknown type for literal #{Macro.to_string(literal)}"
  end

  @spec assert_failed() :: String.t()
  def assert_failed() do
    "Assert failed"
  end

  @spec assume_failed() :: String.t()
  def assume_failed() do
    "Assume failed"
  end

  @spec patter_does_not_match(Macro.t(), Macro.t()) :: String.t()
  def patter_does_not_match(e, p) do
    "#{Macro.to_string(e)} does not match the pattern #{Macro.to_string(p)}"
  end

  @spec no_pattern_holds(Macro.t()) :: String.t()
  def no_pattern_holds(e) do
    "No pattern holds in #{Macro.to_string(e)}"
  end

  @spec bad_previous_branch_to(Macro.t(), Macro.t()) :: String.t()
  def bad_previous_branch_to(p, f) do
    "Bad previous branch to #{Macro.to_string(p)} where #{Macro.to_string(f)}"
  end
end
