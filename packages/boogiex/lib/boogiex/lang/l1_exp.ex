defmodule Boogiex.Lang.L1Exp do
  alias Boogiex.Env
  alias Boogiex.Msg
  alias Boogiex.Lang.L0Exp
  alias Boogiex.Error.EnvError

  @type ast :: Macro.t()

  @spec translate(Env.t(), ast()) :: {L0Exp.ast(), L0Exp.ast()}
  def translate(env, e) do
    translate(env, nil, e)
  end

  @spec translate(Env.t(), ast(), ast()) :: {L0Exp.ast(), L0Exp.ast()}
  def translate(env, assumption, t) when is_tuple(t) and tuple_size(t) < 3 do
    translate(env, assumption, {:{}, [], Tuple.to_list(t)})
  end

  def translate(env, assumption, {:{}, _, args}) do
    arg_results = Enum.map(args, &translate(env, assumption, &1))
    arg_terms = Enum.map(arg_results, &elem(&1, 0))
    arg_sems = Enum.map(arg_results, &elem(&1, 1))

    n = length(arg_terms)
    tuple_n = Env.tuple_constructor(env, n)
    term = quote(do: unquote(tuple_n).(unquote_splicing(arg_terms)))

    {
      term,
      quote do
        unquote_splicing(arg_sems |> Enum.reject(&is_nil/1))

        context unquote(fn -> Msg.tuple_context(args) end) do
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
      end
    }
  end

  def translate(env, assumption, {:or, _, [e1, e2]}) do
    {t1, sem1} = translate(env, assumption, e1)

    {t2, sem2} =
      translate(
        env,
        quote do
          unquote_splicing([assumption] |> Enum.reject(&is_nil/1))
          add !:boolean_val.(unquote(t1))
        end,
        e2
      )

    t = quote(do: :term_or.(unquote(t1), unquote(t2)))

    {
      t,
      quote do
        context unquote(fn -> Msg.or_context(e1, e2) end) do
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
              add :boolean_val.(unquote(t1))
            else
              unquote_splicing([sem2] |> Enum.reject(&is_nil/1))

              when_unsat (
                           unquote_splicing([assumption] |> Enum.reject(&is_nil/1))
                           add :boolean_val.(unquote(t1))
                         ) do
                add !:boolean_val.(unquote(t1))
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
      end
    }
  end

  def translate(env, assumption, {:and, _, [e1, e2]}) do
    {t1, sem1} = translate(env, assumption, e1)

    {t2, sem2} =
      translate(
        env,
        quote do
          unquote_splicing([assumption] |> Enum.reject(&is_nil/1))
          add :boolean_val.(unquote(t1))
        end,
        e2
      )

    t = quote(do: :term_and.(unquote(t1), unquote(t2)))

    {
      t,
      quote do
        context unquote(fn -> Msg.and_context(e1, e2) end) do
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
              add !:boolean_val.(unquote(t1))
            else
              unquote_splicing([sem2] |> Enum.reject(&is_nil/1))

              when_unsat (
                           unquote_splicing([assumption] |> Enum.reject(&is_nil/1))
                           add !:boolean_val.(unquote(t1))
                         ) do
                add :boolean_val.(unquote(t1))
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
    }
  end

  def translate(env, assumption, {fun_name, _, args}) when is_list(args) do
    arg_results = Enum.map(args, &translate(env, assumption, &1))
    arg_terms = Enum.map(arg_results, &elem(&1, 0))
    arg_sems = Enum.map(arg_results, &elem(&1, 1))

    function =
      with nil <- Env.function(env, fun_name, length(arg_terms)) do
        raise EnvError,
          message: Msg.undefined_function(fun_name, args)
      end

    t = quote(do: unquote(function.name).(unquote_splicing(arg_terms)))

    {
      t,
      quote do
        context unquote(fn -> Msg.apply_context(fun_name, args) end) do
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
    }
  end

  def translate(_, _, {var_name, _, _}) do
    {var_name, nil}
  end

  def translate(env, assumption, [{:|, _, [h, t]}]) do
    {head, head_sem} = translate(env, assumption, h)
    {tail, tail_sem} = translate(env, assumption, t)
    list = quote(do: :cons.(unquote(head), unquote(tail)))

    {
      list,
      quote do
        context unquote(fn -> Msg.list_context(h, t) end) do
          unquote_splicing([head_sem] |> Enum.reject(&is_nil/1))
          unquote_splicing([tail_sem] |> Enum.reject(&is_nil/1))
          add :is_nonempty_list.(unquote(list))
          add :hd.(unquote(list)) == unquote(head)
          add :tl.(unquote(list)) == unquote(tail)
        end
      end
    }
  end

  def translate(_, _, []) do
    {nil, nil}
  end

  def translate(env, assumption, [h | t]) do
    translate(env, assumption, [{:|, [], [h, t]}])
  end

  def translate(env, _, literal) do
    lit_type =
      with nil <- Env.lit_type(env, literal) do
        raise EnvError,
          message: Msg.unknown_literal_type(literal)
      end

    lit = quote(do: unquote(lit_type.type_lit).(unquote(literal)))

    {
      lit,
      quote do
        context unquote(fn -> Msg.literal_context(literal) end) do
          add unquote(lit_type.is_type).(unquote(lit))
          add unquote(lit_type.type_val).(unquote(lit)) == unquote(literal)
        end
      end
    }
  end
end
