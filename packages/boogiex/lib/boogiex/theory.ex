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
                  term_is_integer: Term :: Term,
                  term_is_boolean: Term :: Term
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
    {:term_add, [Spec.native(:term_add, :+, :is_integer, :integer_val)]}
  end

  def function(:-, 2) do
    {:term_sub, [Spec.native(:term_sub, :-, :is_integer, :integer_val)]}
  end

  def function(:*, 2) do
    {:term_mul, [Spec.native(:term_mul, :*, :is_integer, :integer_val)]}
  end

  def function(:>=, 2) do
    {:term_gte,
     [
       Spec.native(:term_gte, :>=, :is_integer, :integer_val, :is_boolean, :boolean_val)
     ]}
  end

  def function(:>, 2) do
    {:term_gt,
     [
       Spec.native(:term_gt, :>, :is_integer, :integer_val, :is_boolean, :boolean_val)
     ]}
  end

  def function(:<=, 2) do
    {:term_lte,
     [
       Spec.native(:term_lte, :<=, :is_integer, :integer_val, :is_boolean, :boolean_val)
     ]}
  end

  def function(:<, 2) do
    {:term_lt,
     [
       Spec.native(:term_lt, :<, :is_integer, :integer_val, :is_boolean, :boolean_val)
     ]}
  end

  def function(:and, 2) do
    {:term_and, [Spec.native(:term_and, :&&, :is_boolean, :boolean_val)]}
  end

  def function(:or, 2) do
    {:term_or, [Spec.native(:term_or, :||, :is_boolean, :boolean_val)]}
  end

  def function(:===, 2) do
    {:term_eq,
     [
       Spec.native(:term_eq, :==, :is_boolean, :boolean_val),
       Spec.native(:term_eq, :==, :is_integer, :integer_val, :is_boolean, :boolean_val)
     ]}
  end

  def function(:!==, 2) do
    {:term_neq,
     [
       Spec.native(:term_neq, :!=, :is_boolean, :boolean_val),
       Spec.native(:term_neq, :!=, :is_integer, :integer_val, :is_boolean, :boolean_val)
     ]}
  end

  def function(:not, 1) do
    {:term_not, [Spec.native(:term_not, :!, :is_boolean, :boolean_val)]}
  end

  def function(:-, 1) do
    {:term_neg, [Spec.native(:term_neg, :-, :is_integer, :integer_val)]}
  end

  def function(:is_integer, 1) do
    {:term_is_integer,
     [
       %Spec{
         pre: fn [_] -> true end,
         post: fn [x] ->
           quote do
             :is_boolean.(:term_is_integer.(unquote(x))) &&
               :boolean_val.(:term_is_integer.(unquote(x))) ==
                 :is_integer.(unquote(x))
           end
         end
       }
     ]}
  end

  def function(:is_boolean, 1) do
    {:term_is_boolean,
     [
       %Spec{
         pre: fn [_] -> true end,
         post: fn [x] ->
           quote do
             :is_boolean.(:term_is_boolean.(unquote(x))) &&
               :boolean_val.(:term_is_boolean.(unquote(x))) ==
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
