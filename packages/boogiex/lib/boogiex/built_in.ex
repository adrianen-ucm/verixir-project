defmodule Boogiex.BuiltIn do
  alias SmtLib.Syntax.From
  alias Boogiex.BuiltIn.Spec
  alias Boogiex.BuiltIn.LitType
  alias Boogiex.BuiltIn.Function

  @spec init :: From.ast()
  def init() do
    quote do
      declare_sort Term
      declare_sort Type

      declare_fun type: Term :: Type,
                  integer_val: Term :: Int,
                  boolean_val: Term :: Bool,
                  integer_lit: Int :: Term,
                  boolean_lit: Bool :: Term,
                  tuple_size: Term :: Int,
                  elem: [Term, Int] :: Term,
                  nil: [] :: Term,
                  cons: [Term, Term] :: Term,
                  hd: Term :: Term,
                  tl: Term :: Term

      declare_const int: Type,
                    bool: Type,
                    tuple: Type,
                    nonempty_list: Type

      assert :int != :bool
      assert :int != :tuple
      assert :int != :nonempty_list
      assert :bool != :tuple
      assert :bool != :nonempty_list
      assert :tuple != :nonempty_list

      define_fun is_integer: [x: Term] :: Bool <- :type.(:x) == :int,
                 is_boolean: [x: Term] :: Bool <- :type.(:x) == :bool,
                 is_tuple: [x: Term] :: Bool <- :type.(:x) == :tuple,
                 is_nonempty_list: [x: Term] :: Bool <- :x != nil && :type.(:x) == :nonempty_list,
                 is_list: [x: Term] :: Bool <- :x == nil || :type.(:x) == :nonempty_list

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
                  term_tuple_size: Term :: Term,
                  term_elem: [Term, Term] :: Term,
                  term_is_integer: Term :: Term,
                  term_is_boolean: Term :: Term,
                  term_is_tuple: Term :: Term,
                  term_is_list: Term :: Term
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
          pre: fn [x, y] ->
            quote(
              do:
                :is_tuple.(unquote(x)) && :is_tuple.(unquote(y)) &&
                  :tuple_size.(unquote(x)) == :tuple_size.(unquote(y))
            )
          end,
          post: fn [x, y] ->
            v = fresh([x, y])

            quote(
              do:
                :boolean_val.(:term_eq.(unquote(x), unquote(y))) ==
                  forall(
                    (unquote(v) >= 0 && unquote(v) < :tuple_size.(unquote(x)))
                    ~> (:elem.(unquote(x), unquote(v)) == :elem.(unquote(y), unquote(v))),
                    [{unquote(v), Int}]
                  )
            )
          end
        },
        %Spec{
          pre: fn [x, y] ->
            quote(
              do:
                :is_tuple.(unquote(x)) && :is_tuple.(unquote(y)) &&
                  :tuple_size.(unquote(x)) != :tuple_size.(unquote(y))
            )
          end,
          post: fn [x, y] ->
            quote(do: !:boolean_val.(:term_eq.(unquote(x), unquote(y))))
          end
        },
        %Spec{
          pre: fn [x, y] ->
            quote(do: :is_list.(unquote(x)) && :is_list.(unquote(y)))
          end,
          post: fn [x, y] ->
            quote(
              do:
                :boolean_val.(:term_eq.(unquote(x), unquote(y))) ==
                  ((unquote(x) == nil && unquote(y) == nil) ||
                     (:is_nonempty_list.(unquote(x)) &&
                        :is_nonempty_list.(unquote(y)) &&
                        :hd.(unquote(x)) == :hd.(unquote(y)) &&
                        :tl.(unquote(x)) == :tl.(unquote(y))))
            )
          end
        },
        %Spec{
          post: fn [x, y] ->
            quote(
              do:
                :is_boolean.(:term_eq.(unquote(x), unquote(y))) &&
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
          pre: fn [x, y] ->
            quote(
              do:
                :is_tuple.(unquote(x)) && :is_tuple.(unquote(y)) &&
                  :tuple_size.(unquote(x)) == :tuple_size.(unquote(y))
            )
          end,
          post: fn [x, y] ->
            v = fresh([x, y])

            quote(
              do:
                :boolean_val.(:term_neq.(unquote(x), unquote(y))) ==
                  !forall(
                    (unquote(v) >= 0 && unquote(v) < :tuple_size.(unquote(x)))
                    ~> (:elem.(unquote(x), unquote(v)) == :elem.(unquote(y), unquote(v))),
                    [{unquote(v), Int}]
                  )
            )
          end
        },
        %Spec{
          pre: fn [x, y] ->
            quote(
              do:
                :is_tuple.(unquote(x)) && :is_tuple.(unquote(y)) &&
                  :tuple_size.(unquote(x)) != :tuple_size.(unquote(y))
            )
          end,
          post: fn [x, y] ->
            quote(do: :boolean_val.(:term_neq.(unquote(x), unquote(y))))
          end
        },
        %Spec{
          pre: fn [x, y] ->
            quote(do: :is_list.(unquote(x)) && :is_list.(unquote(y)))
          end,
          post: fn [x, y] ->
            quote(
              do:
                :boolean_val.(:term_neq.(unquote(x), unquote(y))) ==
                  !((unquote(x) == nil && unquote(y) == nil) ||
                      (:is_nonempty_list.(unquote(x)) &&
                         :is_nonempty_list.(unquote(y)) &&
                         :hd.(unquote(x)) == :hd.(unquote(y)) &&
                         :tl.(unquote(x)) == :tl.(unquote(y))))
            )
          end
        },
        %Spec{
          post: fn [x, y] ->
            quote(
              do:
                :is_boolean.(:term_neq.(unquote(x), unquote(y))) &&
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

  def function(:tuple_size, 1) do
    %Function{
      name: :term_tuple_size,
      specs: [
        %Spec{
          pre: fn [x] -> quote(do: :is_tuple.(unquote(x))) end,
          post: fn [x] ->
            quote(
              do:
                :is_integer.(:term_tuple_size.(unquote(x))) &&
                  :integer_val.(:term_tuple_size.(unquote(x))) ==
                    :tuple_size.(unquote(x))
            )
          end
        }
      ]
    }
  end

  def function(:elem, 2) do
    %Function{
      name: :term_elem,
      specs: [
        %Spec{
          pre: fn [x, y] ->
            quote(
              do:
                :is_tuple.(unquote(x)) &&
                  :is_integer.(unquote(y)) &&
                  :integer_val.(unquote(y)) >= 0 &&
                  :integer_val.(unquote(y)) < :tuple_size.(unquote(x))
            )
          end,
          post: fn [x, y] ->
            quote(
              do:
                :term_elem.(unquote(x), unquote(y)) ==
                  :elem.(unquote(x), :integer_val.(unquote(y)))
            )
          end
        }
      ]
    }
  end

  def function(:hd, 1) do
    %Function{
      name: :hd,
      specs: [
        %Spec{
          pre: fn [x] -> quote(do: :is_nonempty_list.(unquote(x))) end
        }
      ]
    }
  end

  def function(:tl, 1) do
    %Function{
      name: :tl,
      specs: [
        %Spec{
          pre: fn [x] -> quote(do: :is_nonempty_list.(unquote(x))) end
        }
      ]
    }
  end

  def function(:is_integer, 1) do
    %Function{
      name: :term_is_integer,
      specs: [
        %Spec{
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

  def function(:is_tuple, 1) do
    %Function{
      name: :term_is_tuple,
      specs: [
        %Spec{
          post: fn [x] ->
            quote(
              do:
                :is_boolean.(:term_is_tuple.(unquote(x))) &&
                  :boolean_val.(:term_is_tuple.(unquote(x))) ==
                    :is_tuple.(unquote(x))
            )
          end
        }
      ]
    }
  end

  def function(:is_list, 1) do
    %Function{
      name: :term_is_list,
      specs: [
        %Spec{
          post: fn [x] ->
            quote(
              do:
                :is_boolean.(:term_is_list.(unquote(x))) &&
                  :boolean_val.(:term_is_list.(unquote(x))) ==
                    :is_list.(unquote(x))
            )
          end
        }
      ]
    }
  end

  def function(_, _) do
    nil
  end

  @spec fresh(From.ast()) :: atom()
  defp fresh(e) do
    {_, vars} =
      Macro.prewalk(e, MapSet.new(), fn
        v, vs when is_atom(v) -> {v, MapSet.put(vs, Atom.to_string(v))}
        other, vs -> {other, vs}
      end)

    Stream.iterate(1, &(&1 + 1))
    |> Stream.map(&"x_#{&1}")
    |> Stream.reject(&(&1 in vars))
    |> Enum.at(0)
    |> String.to_atom()
  end
end
