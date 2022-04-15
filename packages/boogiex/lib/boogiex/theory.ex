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
    {:term_add,
     [
       %Spec{
         pre: fn [x, y] ->
           quote do
             :is_integer.(unquote(x)) && :is_integer.(unquote(y))
           end
         end,
         post: fn [x, y] ->
           quote do
             :is_integer.(:term_add.(unquote(x), unquote(y))) &&
               :integer_val.(:term_add.(unquote(x), unquote(y))) ==
                 :integer_val.(unquote(x)) + :integer_val.(unquote(y))
           end
         end
       }
     ]}
  end

  def function(:-, 2) do
    {:term_sub,
     [
       %Spec{
         pre: fn [x, y] ->
           quote do
             :is_integer.(unquote(x)) && :is_integer.(unquote(y))
           end
         end,
         post: fn [x, y] ->
           quote do
             :is_integer.(:term_sub.(unquote(x), unquote(y))) &&
               :integer_val.(:term_sub.(unquote(x), unquote(y))) ==
                 :integer_val.(unquote(x)) - :integer_val.(unquote(y))
           end
         end
       }
     ]}
  end

  def function(:*, 2) do
    {:term_mul,
     [
       %Spec{
         pre: fn [x, y] ->
           quote do
             :is_integer.(unquote(x)) && :is_integer.(unquote(y))
           end
         end,
         post: fn [x, y] ->
           quote do
             :is_integer.(:term_mul.(unquote(x), unquote(y))) &&
               :integer_val.(:term_mul.(unquote(x), unquote(y))) ==
                 :integer_val.(unquote(x)) * :integer_val.(unquote(y))
           end
         end
       }
     ]}
  end

  def function(:>=, 2) do
    {:term_gte,
     [
       # TODO
     ]}
  end

  def function(:>, 2) do
    {:term_gt,
     [
       # TODO
     ]}
  end

  def function(:<=, 2) do
    {:term_lte,
     [
       # TODO
     ]}
  end

  def function(:<, 2) do
    {:term_lt,
     [
       # TODO
     ]}
  end

  def function(:and, 2) do
    {:term_and,
     [
       %Spec{
         pre: fn [x, _] ->
           quote do
             :is_boolean.(unquote(x)) && !:boolean_val.(unquote(x))
           end
         end,
         post: fn [x, y] ->
           quote do
             :is_boolean.(:term_and.(unquote(x), unquote(y))) &&
               !:boolean_val.(:term_and.(unquote(x), unquote(y)))
           end
         end
       },
       %Spec{
         pre: fn [x, y] ->
           quote do
             :is_boolean.(unquote(x)) &&
               :boolean_val.(unquote(x)) &&
               :is_boolean.(unquote(y))
           end
         end,
         post: fn [x, y] ->
           quote do
             :is_boolean.(:term_and.(unquote(x), unquote(y))) &&
               :boolean_val.(:term_and.(unquote(x), unquote(y))) == :boolean_val.(unquote(y))
           end
         end
       },
       %Spec{
         pre: fn [x, y] ->
           quote do
             :is_boolean.(unquote(x)) &&
               :boolean_val.(unquote(x)) &&
               :is_integer.(unquote(y))
           end
         end,
         post: fn [x, y] ->
           quote do
             :is_integer.(:term_and.(unquote(x), unquote(y))) &&
               :integer_val.(:term_and.(unquote(x), unquote(y))) == :integer_val.(unquote(y))
           end
         end
       }
     ]}
  end

  def function(:or, 2) do
    {:term_or,
     [
       %Spec{
         pre: fn [x, _] ->
           quote do
             :is_boolean.(unquote(x)) && :boolean_val.(unquote(x))
           end
         end,
         post: fn [x, y] ->
           quote do
             :is_boolean.(:term_or.(unquote(x), unquote(y))) &&
               :boolean_val.(:term_or.(unquote(x), unquote(y)))
           end
         end
       },
       %Spec{
         pre: fn [x, y] ->
           quote do
             :is_boolean.(unquote(x)) &&
               !:boolean_val.(unquote(x)) &&
               :is_boolean.(unquote(y))
           end
         end,
         post: fn [x, y] ->
           quote do
             :is_boolean.(:term_or.(unquote(x), unquote(y))) &&
               :boolean_val.(:term_or.(unquote(x), unquote(y))) == :boolean_val.(unquote(y))
           end
         end
       },
       %Spec{
         pre: fn [x, y] ->
           quote do
             :is_boolean.(unquote(x)) &&
               !:boolean_val.(unquote(x)) &&
               :is_integer.(unquote(y))
           end
         end,
         post: fn [x, y] ->
           quote do
             :is_integer.(:term_or.(unquote(x), unquote(y))) &&
               :integer_val.(:term_or.(unquote(x), unquote(y))) == :integer_val.(unquote(y))
           end
         end
       }
     ]}
  end

  def function(:===, 2) do
    {:term_eq,
     [
       %Spec{
         pre: fn [x, y] ->
           quote do
             :is_integer.(unquote(x)) && :is_integer.(unquote(y))
           end
         end,
         post: fn [x, y] ->
           quote do
             :boolean_val.(:term_eq.(unquote(x), unquote(y))) ==
               (:integer_val.(unquote(x)) == :integer_val.(unquote(y)))
           end
         end
       },
       %Spec{
         pre: fn [x, y] ->
           quote do
             :is_boolean.(unquote(x)) && :is_boolean.(unquote(y))
           end
         end,
         post: fn [x, y] ->
           quote do
             :boolean_val.(:term_eq.(unquote(x), unquote(y))) ==
               (:boolean_val.(unquote(x)) == :boolean_val.(unquote(y)))
           end
         end
       },
       %Spec{
         pre: fn [_, _] -> true end,
         post: fn [x, y] ->
           quote do
             :is_boolean.(:term_eq.(unquote(x), unquote(y))) &&
               (unquote(x) == unquote(y))
               ~> :boolean_val.(:term_eq.(unquote(x), unquote(y))) &&
               :boolean_val.(:term_eq.(unquote(x), unquote(y)))
               ~> (:type.(unquote(x)) == :type.(unquote(y)))
           end
         end
       }
     ]}
  end

  def function(:!==, 2) do
    {:term_neq,
     [
       %Spec{
         pre: fn [x, y] ->
           quote do
             :is_integer.(unquote(x)) && :is_integer.(unquote(y))
           end
         end,
         post: fn [x, y] ->
           quote do
             :boolean_val.(:term_neq.(unquote(x), unquote(y))) ==
               (:integer_val.(unquote(x)) != :integer_val.(unquote(y)))
           end
         end
       },
       %Spec{
         pre: fn [x, y] ->
           quote do
             :is_boolean.(unquote(x)) && :is_boolean.(unquote(y))
           end
         end,
         post: fn [x, y] ->
           quote do
             :boolean_val.(:term_neq.(unquote(x), unquote(y))) ==
               (:boolean_val.(unquote(x)) != :boolean_val.(unquote(y)))
           end
         end
       },
       %Spec{
         pre: fn [_, _] -> true end,
         post: fn [x, y] ->
           quote do
             :is_boolean.(:term_neq.(unquote(x), unquote(y))) &&
               (unquote(x) == unquote(y))
               ~> !:boolean_val.(:term_neq.(unquote(x), unquote(y))) &&
               !:boolean_val.(:term_neq.(unquote(x), unquote(y)))
               ~> (:type.(unquote(x)) == :type.(unquote(y)))
           end
         end
       }
     ]}
  end

  def function(:not, 1) do
    {:term_not,
     [
       %Spec{
         pre: fn [x] ->
           quote do
             :is_boolean.(unquote(x))
           end
         end,
         post: fn [x] ->
           quote do
             :is_boolean.(:term_not.(unquote(x))) &&
               :boolean_val.(:term_not.(unquote(x))) ==
                 !:boolean_val.(unquote(x))
           end
         end
       }
     ]}
  end

  def function(:-, 1) do
    {:term_neg,
     [
       %Spec{
         pre: fn [x] ->
           quote do
             :is_integer.(unquote(x))
           end
         end,
         post: fn [x] ->
           quote do
             :is_integer.(:term_neg.(unquote(x))) &&
               :integer_val.(:term_neg.(unquote(x))) ==
                 -:integer_val.(unquote(x))
           end
         end
       }
     ]}
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
