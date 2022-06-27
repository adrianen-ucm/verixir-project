defmodule Boogiex.Lang.L1Exp do
  alias Boogiex.Msg
  alias Boogiex.BuiltIn
  alias Boogiex.Lang.L0Exp
  alias Boogiex.UserDefined
  alias Boogiex.Error.EnvError
  alias Boogiex.BuiltIn.Function
  alias Boogiex.BuiltIn.TupleConstructor

  @type ast :: Macro.t()

  @spec translate(ast(), UserDefined.t(), TupleConstructor.t()) ::
          {{L0Exp.ast(), L0Exp.ast()}, TupleConstructor.t()}
  def translate(e, user_defined, tuple_constructor) do
    translate(e, nil, user_defined, tuple_constructor)
  end

  @spec translate(ast(), ast(), UserDefined.t(), TupleConstructor.t()) ::
          {{L0Exp.ast(), L0Exp.ast()}, TupleConstructor.t()}
  def translate(t, assumption, user_defined, tuple_constructor)
      when is_tuple(t) and tuple_size(t) < 3 do
    translate(
      {:{}, [], Tuple.to_list(t)},
      assumption,
      user_defined,
      tuple_constructor
    )
  end

  def translate({:__block__, _, [e]}, assumption, user_defined, tuple_constructor) do
    translate(e, assumption, user_defined, tuple_constructor)
  end

  def translate({:{}, _, args}, assumption, user_defined, tuple_constructor) do
    {arg_results, tuple_constructor} =
      Enum.map_reduce(
        args,
        tuple_constructor,
        &translate(&1, assumption, user_defined, &2)
      )

    arg_terms = Enum.map(arg_results, &elem(&1, 0))
    arg_sems = Enum.map(arg_results, &elem(&1, 1))

    n = length(arg_terms)
    {tuple_n, tuple_constructor} = TupleConstructor.get(tuple_constructor, n)
    term = quote(do: unquote(tuple_n).(unquote_splicing(arg_terms)))

    {
      {term,
       quote do
         unquote_splicing(arg_sems |> Enum.reject(&is_nil/1))

         context unquote(Msg.tuple_context(args)) do
           add :is_tuple.(unquote(term))
           add :tuple_size.(unquote(term)) == unquote(n)

           unquote_splicing(
             Enum.with_index(arg_terms, fn element, index ->
               quote do
                 add :elem.(unquote(term), unquote(index)) == unquote(element)
               end
             end)
           )
         end
       end},
      tuple_constructor
    }
  end

  def translate({:or, _, [e1, e2]}, assumption, user_defined, tuple_constructor) do
    {{t1, sem1}, tuple_constructor} =
      translate(
        e1,
        assumption,
        user_defined,
        tuple_constructor
      )

    {{t2, sem2}, tuple_constructor} =
      translate(
        e2,
        quote do
          unquote_splicing([assumption] |> Enum.reject(&is_nil/1))
          add !:boolean_val.(unquote(t1))
        end,
        user_defined,
        tuple_constructor
      )

    t = quote(do: :term_or.(unquote(t1), unquote(t2)))

    {
      {t,
       quote do
         context unquote(Msg.or_context(e1, e2)) do
           unquote_splicing([sem1] |> Enum.reject(&is_nil/1))

           when_unsat (
                        unquote_splicing([assumption] |> Enum.reject(&is_nil/1))
                        add !:is_boolean.(unquote(t1))
                      ) do
             when_unsat (
                          unquote_splicing([assumption] |> Enum.reject(&is_nil/1))
                          add !:boolean_val.(unquote(t1))
                        ) do
               add :is_boolean.(unquote(t))
               add :boolean_val.(unquote(t))
             else
               unquote_splicing([sem2] |> Enum.reject(&is_nil/1))

               when_unsat (
                            unquote_splicing([assumption] |> Enum.reject(&is_nil/1))
                            add :boolean_val.(unquote(t1))
                          ) do
                 add unquote(t) == unquote(t2)
               else
                 when_unsat (
                              unquote_splicing([assumption] |> Enum.reject(&is_nil/1))
                              add !:boolean_val.(unquote(t1))
                              add !:is_boolean.(unquote(t2))
                            ) do
                   add :is_boolean.(unquote(t))

                   add :boolean_val.(unquote(t)) ==
                         (:boolean_val.(unquote(t1)) ||
                            :boolean_val.(unquote(t2)))
                 else
                   fail unquote(Msg.not_boolean(e2))
                 end
               end
             end
           else
             fail unquote(Msg.not_boolean(e1))
           end
         end
       end},
      tuple_constructor
    }
  end

  def translate({:and, _, [e1, e2]}, assumption, user_defined, tuple_constructor) do
    {{t1, sem1}, tuple_constructor} =
      translate(
        e1,
        assumption,
        user_defined,
        tuple_constructor
      )

    {{t2, sem2}, tuple_constructor} =
      translate(
        e2,
        quote do
          unquote_splicing([assumption] |> Enum.reject(&is_nil/1))
          add :boolean_val.(unquote(t1))
        end,
        user_defined,
        tuple_constructor
      )

    t = quote(do: :term_and.(unquote(t1), unquote(t2)))

    {
      {
        t,
        quote do
          context unquote(Msg.and_context(e1, e2)) do
            unquote_splicing([sem1] |> Enum.reject(&is_nil/1))

            when_unsat (
                         unquote_splicing([assumption] |> Enum.reject(&is_nil/1))
                         add !:is_boolean.(unquote(t1))
                       ) do
              when_unsat (
                           unquote_splicing([assumption] |> Enum.reject(&is_nil/1))
                           add :boolean_val.(unquote(t1))
                         ) do
                add :is_boolean.(unquote(t))
                add !:boolean_val.(unquote(t))
              else
                unquote_splicing([sem2] |> Enum.reject(&is_nil/1))

                when_unsat (
                             unquote_splicing([assumption] |> Enum.reject(&is_nil/1))
                             add !:boolean_val.(unquote(t1))
                           ) do
                  add unquote(t) == unquote(t2)
                else
                  when_unsat (
                               unquote_splicing([assumption] |> Enum.reject(&is_nil/1))
                               add :boolean_val.(unquote(t1))
                               add !:is_boolean.(unquote(t2))
                             ) do
                    add :is_boolean.(unquote(t))

                    add :boolean_val.(unquote(t)) ==
                          (:boolean_val.(unquote(t1)) &&
                             :boolean_val.(unquote(t2)))
                  else
                    fail unquote(Msg.not_boolean(e2))
                  end
                end
              end
            else
              fail unquote(Msg.not_boolean(e1))
            end
          end
        end
      },
      tuple_constructor
    }
  end

  def translate({fun_name, _, args}, assumption, user_defined, tuple_constructor)
      when is_list(args) do
    {arg_results, tuple_constructor} =
      Enum.map_reduce(
        args,
        tuple_constructor,
        &translate(&1, assumption, user_defined, &2)
      )

    arg_terms = Enum.map(arg_results, &elem(&1, 0))
    arg_sems = Enum.map(arg_results, &elem(&1, 1))
    arity = length(args)

    function =
      with nil <- BuiltIn.function(fun_name, arity) do
        if {fun_name, arity} in UserDefined.functions(user_defined) do
          %Function{name: fun_name}
        end
      end

    with nil <- function do
      raise EnvError,
        message: Msg.undefined_function(fun_name, args)
    end

    t = quote(do: unquote(function.name).(unquote_splicing(arg_terms)))

    {
      {
        t,
        quote do
          context unquote(Msg.apply_context(fun_name, args)) do
            unquote_splicing(arg_sems |> Enum.reject(&is_nil/1))

            when_unsat (
                         unquote_splicing([assumption] |> Enum.reject(&is_nil/1))

                         add !unquote(
                               Enum.reduce(
                                 function.specs,
                                 Enum.empty?(function.specs),
                                 fn s, a ->
                                   quote(do: unquote(a) || unquote(s.pre.(arg_terms)))
                                 end
                               )
                             )
                       ) do
            else
              fail unquote(Msg.no_precondition_holds(fun_name, args))
            end

            unquote_splicing(
              Enum.map(function.specs, fn s ->
                quote do
                  when_unsat (
                               unquote_splicing([assumption] |> Enum.reject(&is_nil/1))
                               add !unquote(s.pre.(arg_terms))
                             ) do
                    add unquote(s.pre.(arg_terms))
                    add unquote(s.post.(arg_terms))
                  end
                end
              end)
            )
          end
        end
      },
      tuple_constructor
    }
  end

  def translate({var_name, _, _}, _, _, tuple_constructor) do
    {{var_name, nil}, tuple_constructor}
  end

  def translate([{:|, _, [h, t]}], assumption, user_defined, tuple_constructor) do
    {{head, head_sem}, tuple_constructor} =
      translate(h, assumption, user_defined, tuple_constructor)

    {{tail, tail_sem}, tuple_constructor} =
      translate(t, assumption, user_defined, tuple_constructor)

    list = quote(do: :cons.(unquote(head), unquote(tail)))

    {
      {
        list,
        quote do
          context unquote(Msg.list_context(h, t)) do
            unquote_splicing([head_sem] |> Enum.reject(&is_nil/1))
            unquote_splicing([tail_sem] |> Enum.reject(&is_nil/1))
            add :is_nonempty_list.(unquote(list))
            add :hd.(unquote(list)) == unquote(head)
            add :tl.(unquote(list)) == unquote(tail)
          end
        end
      },
      tuple_constructor
    }
  end

  def translate([], _, _, tuple_constructor) do
    {{nil, nil}, tuple_constructor}
  end

  def translate([h | t], assumption, user_defined, tuple_constructor) do
    translate([{:|, [], [h, t]}], assumption, user_defined, tuple_constructor)
  end

  def translate(literal, _, _, tuple_constructor) do
    lit_type =
      with nil <- BuiltIn.lit_type(literal) do
        raise EnvError,
          message: Msg.unknown_literal_type(literal)
      end

    lit = quote(do: unquote(lit_type.type_lit).(unquote(literal)))

    {
      {
        lit,
        quote do
          context unquote(Msg.literal_context(literal)) do
            add unquote(lit_type.is_type).(unquote(lit))
            add unquote(lit_type.type_val).(unquote(lit)) == unquote(literal)
          end
        end
      },
      tuple_constructor
    }
  end
end
