defmodule Boogiex.Msg do
  @type t :: nil | String.t() | (() -> String.t())

  @spec to_string(t()) :: String.t()
  def to_string(nil) do
    ""
  end

  def to_string(s) when is_bitstring(s) do
    s
  end

  def to_string(f) when is_function(f) do
    f.()
  end

  @spec evaluate_stm_context(Macro.t()) :: t()
  def evaluate_stm_context(ast) do
    fn -> "evaluating statement #{Macro.to_string(ast)}" end
  end

  @spec havoc_context(Macro.t()) :: t()
  def havoc_context(ast) do
    fn -> "declaring the variable #{Macro.to_string(ast)}" end
  end

  @spec assume_context(Macro.t()) :: t()
  def assume_context(ast) do
    fn -> "trying to assume #{Macro.to_string(ast)}" end
  end

  @spec assert_context(Macro.t()) :: t()
  def assert_context(ast) do
    fn -> "trying to assert #{Macro.to_string(ast)}" end
  end

  @spec block_context() :: t()
  def block_context() do
    fn -> "evaluating a block" end
  end

  @spec tuple_context([Macro.t()]) :: t()
  def tuple_context(args) do
    fn -> "processing the tuple with contents #{Macro.to_string(args)}" end
  end

  @spec or_context(Macro.t(), Macro.t()) :: t()
  def or_context(e1, e2) do
    fn -> "processing #{Macro.to_string(e1)} or #{Macro.to_string(e2)}" end
  end

  @spec and_context(Macro.t(), Macro.t()) :: t()
  def and_context(e1, e2) do
    fn -> "processing #{Macro.to_string(e1)} and #{Macro.to_string(e2)}" end
  end

  @spec apply_context(Macro.t(), [Macro.t()]) :: t()
  def apply_context(f, args) do
    fn -> "processing #{Atom.to_string(f)}/#{length(args)}" end
  end

  @spec list_context(Macro.t(), Macro.t()) :: t()
  def list_context(h, t) do
    fn -> "processing the list with head #{Macro.to_string(h)} and tail #{Macro.to_string(t)}" end
  end

  @spec literal_context(Macro.t()) :: t()
  def literal_context(ast) do
    fn -> "processing the literal #{Macro.to_string(ast)}" end
  end

  @spec initialize_smt_context() :: t()
  def initialize_smt_context() do
    fn -> "executing the Boogiex SMT-LIB initialization code" end
  end

  @spec initialize_user_defined_context() :: t()
  def initialize_user_defined_context() do
    fn -> "declaring the user defined functions" end
  end

  @spec tuple_constructor_context(atom()) :: t()
  def tuple_constructor_context(name) do
    fn -> "declaring the tuple constructor #{name}" end
  end

  @spec could_not_start_tuple_constructor(any()) :: t()
  def could_not_start_tuple_constructor(e) do
    fn -> "Could not start the tuple constructor agent: #{inspect(e)}" end
  end

  @spec undefined_user_defined_function(atom(), [Macro.t()]) :: t()
  def undefined_user_defined_function(fun_name, args) do
    fn -> "No definition for #{Atom.to_string(fun_name)}/#{length(args)}" end
  end

  @spec body_expansion_does_not_hold(atom(), [Macro.t()]) :: t()
  def body_expansion_does_not_hold(fun_name, args) do
    fn -> "#{Atom.to_string(fun_name)}/#{length(args)} body expansion does not hold" end
  end

  @spec precondition_does_not_hold(atom(), [Macro.t()]) :: t()
  def precondition_does_not_hold(fun_name, args) do
    fn -> "A #{Atom.to_string(fun_name)}/#{length(args)} precondition does not hold" end
  end

  @spec postcondition_does_not_hold(atom(), [Macro.t()]) :: t()
  def postcondition_does_not_hold(fun_name, args) do
    fn -> "A #{Atom.to_string(fun_name)}/#{length(args)} postcondition does not hold" end
  end

  @spec no_precondition_holds(atom(), [Macro.t()]) :: t()
  def no_precondition_holds(fun_name, args) do
    fn -> "No precondition for #{Atom.to_string(fun_name)}/#{length(args)} holds" end
  end

  @spec not_boolean(Macro.t()) :: t()
  def not_boolean(ast) do
    fn -> "#{Macro.to_string(ast)} is not boolean" end
  end

  @spec undefined_function(atom(), [Macro.t()]) :: t()
  def undefined_function(fun_name, args) do
    fn -> "Undefined function #{Atom.to_string(fun_name)}/#{length(args)}" end
  end

  @spec unknown_literal_type(Macro.t()) :: t()
  def unknown_literal_type(literal) do
    fn -> "Unknown type for literal #{Macro.to_string(literal)}" end
  end

  @spec assert_failed(Macro.t()) :: t()
  def assert_failed(e) do
    fn -> "Assert failed #{Macro.to_string(e)}" end
  end

  @spec assume_failed(Macro.t()) :: t()
  def assume_failed(e) do
    fn -> "Assume failed #{Macro.to_string(e)}" end
  end

  @spec pattern_does_not_match(Macro.t(), Macro.t()) :: t()
  def pattern_does_not_match(e, p) do
    fn -> "#{Macro.to_string(e)} does not match the pattern #{Macro.to_string(p)}" end
  end

  @spec no_case_pattern_holds_for(Macro.t()) :: t()
  def no_case_pattern_holds_for(e) do
    fn -> "No case pattern holds for #{Macro.to_string(e)}" end
  end

  @spec bad_previous_branch_to(Macro.t(), Macro.t()) :: t()
  def bad_previous_branch_to(p, f) do
    fn -> "Bad previous branch to #{Macro.to_string(p)} where #{Macro.to_string(f)}" end
  end

  @spec guard_does_not_hold(Macro.t()) :: t()
  def guard_does_not_hold(g) do
    fn -> "Guard #{Macro.to_string(g)} des not hold" end
  end

  @spec free_var_in_ssa(atom()) :: t()
  def free_var_in_ssa(v) do
    fn ->
      "Applying SSA to a program with the free variable #{v}. The result may be inconsistent."
    end
  end
end
