defmodule Boogiex.Theory do
  alias SmtLib.Syntax.From
  alias Boogiex.Theory.Spec
  alias Boogiex.Theory.LitType
  alias Boogiex.Theory.Function

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

  @spec lit_type(term()) :: LitType.t() | nil
  def lit_type(n) when is_integer(n) do
    %LitType{
      is_type: :is_integer,
      type_val: :integer_val,
      type_lit: :integer_lit
    }
  end

  def lit_type(b) when is_boolean(b) do
    %LitType{
      is_type: :is_boolean,
      type_val: :boolean_val,
      type_lit: :boolean_lit
    }
  end

  def lit_type(_) do
    nil
  end

  @spec declare_function(atom(), non_neg_integer()) :: From.ast()
  def declare_function(name, arity) do
    quote(
      do:
        declare_fun([
          {
            unquote(name),
            [unquote_splicing(List.duplicate(:Term, arity))] :: Term
          }
        ])
    )
  end

  @spec function(atom(), non_neg_integer()) :: Function.t() | nil
  def function(:+, 2) do
    %Function{
      name: :term_add,
      specs: [
        %Spec{
          pre: fn [x, y] ->
            quote(do: :is_integer.(unquote(x)) && :is_integer.(unquote(y)))
          end,
          post: fn [x, y] ->
            quote(
              do:
                :is_integer.(:term_add.(unquote(x), unquote(y))) &&
                  :integer_val.(:term_add.(unquote(x), unquote(y))) ==
                    :integer_val.(unquote(x)) + :integer_val.(unquote(y))
            )
          end
        }
      ]
    }
  end

  def function(:-, 2) do
    %Function{
      name: :term_sub,
      specs: [
        %Spec{
          pre: fn [x, y] ->
            quote(do: :is_integer.(unquote(x)) && :is_integer.(unquote(y)))
          end,
          post: fn [x, y] ->
            quote(
              do:
                :is_integer.(:term_sub.(unquote(x), unquote(y))) &&
                  :integer_val.(:term_sub.(unquote(x), unquote(y))) ==
                    :integer_val.(unquote(x)) - :integer_val.(unquote(y))
            )
          end
        }
      ]
    }
  end

  def function(:*, 2) do
    %Function{
      name: :term_mul,
      specs: [
        %Spec{
          pre: fn [x, y] ->
            quote(do: :is_integer.(unquote(x)) && :is_integer.(unquote(y)))
          end,
          post: fn [x, y] ->
            quote(
              do:
                :is_integer.(:term_mul.(unquote(x), unquote(y))) &&
                  :integer_val.(:term_mul.(unquote(x), unquote(y))) ==
                    :integer_val.(unquote(x)) * :integer_val.(unquote(y))
            )
          end
        }
      ]
    }
  end

  def function(:>=, 2) do
    %Function{
      name: :term_gte,
      specs: [
        %Spec{
          pre: fn [x, y] ->
            quote(do: :is_integer.(unquote(x)) && :is_integer.(unquote(y)))
          end,
          post: fn [x, y] ->
            quote(
              do:
                :is_boolean.(:term_gte.(unquote(x), unquote(y))) &&
                  :boolean_val.(:term_gte.(unquote(x), unquote(y))) ==
                    :integer_val.(unquote(x)) >= :integer_val.(unquote(y))
            )
          end
        }
      ]
    }
  end

  def function(:>, 2) do
    %Function{
      name: :term_gt,
      specs: [
        %Spec{
          pre: fn [x, y] ->
            quote(do: :is_integer.(unquote(x)) && :is_integer.(unquote(y)))
          end,
          post: fn [x, y] ->
            quote(
              do:
                :is_boolean.(:term_gt.(unquote(x), unquote(y))) &&
                  :boolean_val.(:term_gt.(unquote(x), unquote(y))) ==
                    :integer_val.(unquote(x)) > :integer_val.(unquote(y))
            )
          end
        }
      ]
    }
  end

  def function(:<=, 2) do
    %Function{
      name: :term_lte,
      specs: [
        %Spec{
          pre: fn [x, y] ->
            quote(do: :is_integer.(unquote(x)) && :is_integer.(unquote(y)))
          end,
          post: fn [x, y] ->
            quote(
              do:
                :is_boolean.(:term_lte.(unquote(x), unquote(y))) &&
                  :boolean_val.(:term_lte.(unquote(x), unquote(y))) ==
                    :integer_val.(unquote(x)) <= :integer_val.(unquote(y))
            )
          end
        }
      ]
    }
  end

  def function(:<, 2) do
    %Function{
      name: :term_lt,
      specs: [
        %Spec{
          pre: fn [x, y] ->
            quote(do: :is_integer.(unquote(x)) && :is_integer.(unquote(y)))
          end,
          post: fn [x, y] ->
            quote(
              do:
                :is_boolean.(:term_lt.(unquote(x), unquote(y))) &&
                  :boolean_val.(:term_lt.(unquote(x), unquote(y))) ==
                    :integer_val.(unquote(x)) < :integer_val.(unquote(y))
            )
          end
        }
      ]
    }
  end

  def function(:and, 2) do
    %Function{
      name: :term_and,
      specs: [
        %Spec{
          pre: fn [x, y] ->
            quote(do: :is_boolean.(unquote(x)) && :is_boolean.(unquote(y)))
          end,
          post: fn [x, y] ->
            quote(
              do:
                :is_boolean.(:term_and.(unquote(x), unquote(y))) &&
                  :boolean_val.(:term_and.(unquote(x), unquote(y))) ==
                    (:boolean_val.(unquote(x)) && :boolean_val.(unquote(y)))
            )
          end
        },
        %Spec{
          pre: fn [x, _] ->
            quote(do: :is_boolean.(unquote(x)) && !:boolean_val.(unquote(x)))
          end,
          post: fn [x, y] ->
            quote(do: :term_and.(unquote(x), unquote(y)) == unquote(x))
          end
        },
        %Spec{
          pre: fn [x, y] ->
            quote(
              do:
                :is_boolean.(unquote(x)) && :boolean_val.(unquote(x)) &&
                  :is_integer.(unquote(y))
            )
          end,
          post: fn [x, y] ->
            quote(do: :term_and.(unquote(x), unquote(y)) == unquote(y))
          end
        }
      ]
    }
  end

  def function(:or, 2) do
    %Function{
      name: :term_or,
      specs: [
        %Spec{
          pre: fn [x, y] ->
            quote(do: :is_boolean.(unquote(x)) && :is_boolean.(unquote(y)))
          end,
          post: fn [x, y] ->
            quote(
              do:
                :is_boolean.(:term_or.(unquote(x), unquote(y))) &&
                  :boolean_val.(:term_or.(unquote(x), unquote(y))) ==
                    (:boolean_val.(unquote(x)) || :boolean_val.(unquote(y)))
            )
          end
        },
        %Spec{
          pre: fn [x, _] ->
            quote(do: :is_boolean.(unquote(x)) && :boolean_val.(unquote(x)))
          end,
          post: fn [x, y] ->
            quote(do: :term_or.(unquote(x), unquote(y)) == unquote(x))
          end
        },
        %Spec{
          pre: fn [x, y] ->
            quote(
              do:
                :is_boolean.(unquote(x)) && !:boolean_val.(unquote(x)) &&
                  :is_integer.(unquote(y))
            )
          end,
          post: fn [x, y] ->
            quote(do: :term_or.(unquote(x), unquote(y)) == unquote(y))
          end
        }
      ]
    }
  end

  def function(:===, 2) do
    %Function{
      name: :term_eq,
      specs: [
        %Spec{
          pre: fn [x, y] ->
            quote(do: :is_integer.(unquote(x)) && :is_integer.(unquote(y)))
          end,
          post: fn [x, y] ->
            quote(
              do:
                :boolean_val.(:term_eq.(unquote(x), unquote(y))) ==
                  (:integer_val.(unquote(x)) == :integer_val.(unquote(y)))
            )
          end
        },
        %Spec{
          pre: fn [x, y] ->
            quote(do: :is_boolean.(unquote(x)) && :is_boolean.(unquote(y)))
          end,
          post: fn [x, y] ->
            quote(
              do:
                :boolean_val.(:term_eq.(unquote(x), unquote(y))) ==
                  (:boolean_val.(unquote(x)) == :boolean_val.(unquote(y)))
            )
          end
        },
        %Spec{
          pre: fn [_, _] -> true end,
          post: fn [x, y] ->
            quote(do: :is_boolean.(:term_eq.(unquote(x), unquote(y))))
          end
        },
        %Spec{
          pre: fn [_, _] -> true end,
          post: fn [x, y] ->
            quote(
              do:
                :boolean_val.(:term_eq.(unquote(x), unquote(y)))
                <~> (unquote(x) == unquote(y))
            )
          end
        }
      ]
    }
  end

  def function(:!==, 2) do
    %Function{
      name: :term_neq,
      specs: [
        %Spec{
          pre: fn [x, y] ->
            quote(do: :is_integer.(unquote(x)) && :is_integer.(unquote(y)))
          end,
          post: fn [x, y] ->
            quote(
              do:
                :boolean_val.(:term_neq.(unquote(x), unquote(y))) ==
                  (:integer_val.(unquote(x)) != :integer_val.(unquote(y)))
            )
          end
        },
        %Spec{
          pre: fn [x, y] ->
            quote(do: :is_boolean.(unquote(x)) && :is_boolean.(unquote(y)))
          end,
          post: fn [x, y] ->
            quote(
              do:
                :boolean_val.(:term_neq.(unquote(x), unquote(y))) ==
                  (:boolean_val.(unquote(x)) != :boolean_val.(unquote(y)))
            )
          end
        },
        %Spec{
          pre: fn [_, _] -> true end,
          post: fn [x, y] ->
            quote(do: :is_boolean.(:term_neq.(unquote(x), unquote(y))))
          end
        },
        %Spec{
          pre: fn [_, _] -> true end,
          post: fn [x, y] ->
            quote(
              do:
                :boolean_val.(:term_neq.(unquote(x), unquote(y)))
                <~> (unquote(x) != unquote(y))
            )
          end
        }
      ]
    }
  end

  def function(:not, 1) do
    %Function{
      name: :term_not,
      specs: [
        %Spec{
          pre: fn [x] ->
            quote(do: :is_boolean.(unquote(x)))
          end,
          post: fn [x] ->
            quote(
              do:
                :is_boolean.(:term_not.(unquote(x))) &&
                  :boolean_val.(:term_not.(unquote(x))) ==
                    !:boolean_val.(unquote(x))
            )
          end
        }
      ]
    }
  end

  def function(:-, 1) do
    %Function{
      name: :term_neg,
      specs: [
        %Spec{
          pre: fn [x] ->
            quote(do: :is_integer.(unquote(x)))
          end,
          post: fn [x] ->
            quote(
              do:
                :is_integer.(:term_neg.(unquote(x))) &&
                  :integer_val.(:term_neg.(unquote(x))) ==
                    -:integer_val.(unquote(x))
            )
          end
        }
      ]
    }
  end

  def function(:is_integer, 1) do
    %Function{
      name: :term_is_integer,
      specs: [
        %Spec{
          pre: fn [_] -> true end,
          post: fn [x] ->
            quote(
              do:
                :is_boolean.(:term_is_integer.(unquote(x))) &&
                  :boolean_val.(:term_is_integer.(unquote(x))) ==
                    :is_integer.(unquote(x))
            )
          end
        }
      ]
    }
  end

  def function(:is_boolean, 1) do
    %Function{
      name: :term_is_boolean,
      specs: [
        %Spec{
          pre: fn [_] -> true end,
          post: fn [x] ->
            quote(
              do:
                :is_boolean.(:term_is_boolean.(unquote(x))) &&
                  :boolean_val.(:term_is_boolean.(unquote(x))) ==
                    :is_boolean.(unquote(x))
            )
          end
        }
      ]
    }
  end

  def function(_, _) do
    nil
  end
end
