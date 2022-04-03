defmodule Boogiex.Theory do
  alias SmtLib.Syntax.From
  alias Boogiex.Theory.Spec

  @spec init :: From.ast()
  def init() do
    quote do
      declare_sort Term
      declare_sort Type

      declare_fun type: Term :: Type,
                  integer_val: Term :: Int,
                  boolean_val: Term :: Bool,
                  integer_lit: Int :: Term,
                  boolean_lit: Bool :: Term

      declare_const int: Type,
                    bool: Type

      assert :int != :bool

      define_fun is_integer: [x: Term] :: Bool <- :type.(:x) == :int,
                 is_boolean: [x: Term] :: Bool <- :type.(:x) == :bool

      declare_fun term_add: [Term, Term] :: Term,
                  term_sub: [Term, Term] :: Term,
                  term_mul: [Term, Term] :: Term,
                  term_gte: [Term, Term] :: Term,
                  term_gt: [Term, Term] :: Term,
                  term_lte: [Term, Term] :: Term,
                  term_lt: [Term, Term] :: Term,
                  term_and: [Term, Term] :: Term,
                  term_or: [Term, Term] :: Term,
                  term_if: [Term, Term] :: Term,
                  term_iff: [Term, Term] :: Term,
                  term_eq: [Term, Term] :: Term,
                  term_neq: [Term, Term] :: Term,
                  term_not: [Term] :: Term,
                  term_neg: [Term] :: Term,
                  is_integer_: Term :: Term,
                  is_boolean_: Term :: Term
    end
  end

  @spec literal(term()) :: {atom(), atom(), atom()} | nil
  def literal(n) when is_integer(n) do
    {:is_integer, :integer_val, :integer_lit}
  end

  def literal(b) when is_boolean(b) do
    {:is_boolean, :boolean_val, :boolean_lit}
  end

  def literal(_) do
    nil
  end

  @spec function(atom(), non_neg_integer()) :: {atom(), [Spec.t()]} | nil
  def function(:+, 2) do
    {:term_add, [Spec.binary_native(:term_add, :+, :is_integer, :integer_val)]}
  end

  def function(:-, 2) do
    {:term_sub, [Spec.binary_native(:term_sub, :-, :is_integer, :integer_val)]}
  end

  def function(:*, 2) do
    {:term_mul, [Spec.binary_native(:term_mul, :*, :is_integer, :integer_val)]}
  end

  def function(:>=, 2) do
    {:term_gte,
     [
       Spec.binary_native(:term_gte, :>=, :is_integer, :integer_val, :is_boolean, :boolean_val)
     ]}
  end

  def function(:>, 2) do
    {:term_gt,
     [
       Spec.binary_native(:term_gt, :>, :is_integer, :integer_val, :is_boolean, :boolean_val)
     ]}
  end

  def function(:<=, 2) do
    {:term_lte,
     [
       Spec.binary_native(:term_lte, :<=, :is_integer, :integer_val, :is_boolean, :boolean_val)
     ]}
  end

  def function(:<, 2) do
    {:term_lt,
     [
       Spec.binary_native(:term_lt, :<, :is_integer, :integer_val, :is_boolean, :boolean_val)
     ]}
  end

  def function(:&&, 2) do
    {:term_and, [Spec.binary_native(:term_and, :&&, :is_boolean, :boolean_val)]}
  end

  def function(:||, 2) do
    {:term_or, [Spec.binary_native(:term_or, :||, :is_boolean, :boolean_val)]}
  end

  def function(:~>, 2) do
    {:term_if, [Spec.binary_native(:term_if, :~>, :is_boolean, :boolean_val)]}
  end

  def function(:<~>, 2) do
    {:term_iff, [Spec.binary_native(:term_iff, :<~>, :is_boolean, :boolean_val)]}
  end

  def function(:==, 2) do
    {:term_eq,
     [
       Spec.binary_native(:term_eq, :==, :is_boolean, :boolean_val),
       Spec.binary_native(:term_eq, :==, :is_integer, :integer_val, :is_boolean, :boolean_val)
     ]}
  end

  def function(:!=, 2) do
    {:term_neq,
     [
       Spec.binary_native(:term_neq, :!=, :is_boolean, :boolean_val),
       Spec.binary_native(:term_neq, :!=, :is_integer, :integer_val, :is_boolean, :boolean_val)
     ]}
  end

  def function(:!, 1) do
    {:term_not, [Spec.unary_native(:term_not, :!, :is_boolean, :boolean_val)]}
  end

  def function(:-, 1) do
    {:term_neg, [Spec.unary_native(:term_neg, :-, :is_integer, :integer_val)]}
  end

  def function(:is_integer, 1) do
    {:is_integer_,
     [
       %Spec{
         pre: fn [_] -> true end,
         post: fn [x] ->
           quote do
             :is_boolean.(:is_integer_.(unquote(x))) &&
               :boolean_val.(:is_integer_.(unquote(x))) ==
                 :is_integer.(unquote(x))
           end
         end
       }
     ]}
  end

  def function(:is_boolean, 1) do
    {:is_boolean_,
     [
       %Spec{
         pre: fn [_] -> true end,
         post: fn [x] ->
           quote do
             :is_boolean.(:is_boolean_.(unquote(x))) &&
               :boolean_val.(:is_boolean_.(unquote(x))) ==
                 :is_boolean.(unquote(x))
           end
         end
       }
     ]}
  end

  def function(_, _) do
    nil
  end
end
