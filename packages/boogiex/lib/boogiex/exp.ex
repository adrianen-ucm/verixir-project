defmodule Boogiex.Exp do
  alias Boogiex.Env
  alias Boogiex.Env.Smt
  alias SmtLib.Syntax.From
  alias Boogiex.Error.EnvError

  @type ast :: Macro.t()

  @spec exp(Env.t(), ast()) :: {From.ast(), [term()]}
  def exp(env, t) when is_tuple(t) and tuple_size(t) < 3 do
    exp(env, {:{}, [], Tuple.to_list(t)})
  end

  def exp(env, {:{}, _, args}) do
    arg_results = Enum.map(args, &exp(env, &1))
    arg_terms = Enum.map(arg_results, &elem(&1, 0))
    arg_errors = Enum.flat_map(arg_results, &elem(&1, 1))

    n = length(arg_terms)
    tuple_n = Env.tuple_constructor(env, n)
    term = quote(do: unquote(tuple_n).(unquote_splicing(arg_terms)))

    Smt.run(
      env,
      fn -> tuple_context(args) end,
      quote do
        assert :is_tuple.(unquote(term))
        assert :tuple_size.(unquote(term)) == unquote(n)

        unquote(
          Enum.with_index(arg_terms, fn element, index ->
            quote(do: assert(:elem.(unquote(term), unquote(index)) == unquote(element)))
          end)
        )
      end
    )

    {term, arg_errors}
  end

  def exp(env, {:or, _, [e1, e2]}) do
    {t1, errors} = exp(env, e1)

    valid_type =
      Smt.check_valid(
        env,
        fn -> or_context(e1, e2) end,
        quote(do: :is_boolean.(unquote(t1)))
      )

    errors =
      if(
        valid_type,
        do: errors,
        else: ["#{Macro.to_string(e1)} is not boolean" | errors]
      )

    always_true =
      Smt.check_valid(
        env,
        fn -> or_context(e1, e2) end,
        quote(do: :boolean_val.(unquote(t1)))
      )

    if always_true do
      {t, errors_2} = exp(env, true)
      {t, Enum.concat(errors, errors_2)}
    else
      always_false =
        Smt.check_valid(
          env,
          fn -> or_context(e1, e2) end,
          quote(do: !:boolean_val.(unquote(t1)))
        )

      {t2, errors_2} = exp(env, e2)

      errors = Enum.concat(errors, errors_2)

      if always_false do
        {t2, errors}
      else
        valid_type =
          Smt.check_valid(
            env,
            fn -> or_context(e1, e2) end,
            quote(do: :is_boolean.(unquote(t2)))
          )

        errors =
          if(
            valid_type,
            do: errors,
            else: ["#{Macro.to_string(e2)} is not boolean" | errors]
          )

        t = quote(do: :term_or.(unquote(t1), unquote(t2)))

        Smt.run(
          env,
          fn -> or_context(e1, e2) end,
          quote do
            assert :is_boolean.(unquote(t)) &&
                     :boolean_val.(unquote(t)) ==
                       (:boolean_val.(unquote(t1)) || :boolean_val.(unquote(t2)))
          end
        )

        {t, errors}
      end
    end
  end

  def exp(env, {:and, _, [e1, e2]}) do
    {t1, errors} = exp(env, e1)

    valid_type =
      Smt.check_valid(
        env,
        fn -> and_context(e1, e2) end,
        quote(do: :is_boolean.(unquote(t1)))
      )

    errors =
      if(
        valid_type,
        do: errors,
        else: ["#{Macro.to_string(e1)} is not boolean" | errors]
      )

    always_false =
      Smt.check_valid(
        env,
        fn -> and_context(e1, e2) end,
        quote(do: !:boolean_val.(unquote(t1)))
      )

    if always_false do
      {t, errors_2} = exp(env, true)
      {t, Enum.concat(errors, errors_2)}
    else
      always_true =
        Smt.check_valid(
          env,
          fn -> and_context(e1, e2) end,
          quote(do: :boolean_val.(unquote(t1)))
        )

      {t2, errors_2} = exp(env, e2)

      errors = Enum.concat(errors, errors_2)

      if always_true do
        {t2, errors}
      else
        valid_type =
          Smt.check_valid(
            env,
            fn -> and_context(e1, e2) end,
            quote(do: :is_boolean.(unquote(t2)))
          )

        errors =
          if(
            valid_type,
            do: errors,
            else: ["#{Macro.to_string(e2)} is not boolean" | errors]
          )

        t = quote(do: :term_and.(unquote(t1), unquote(t2)))

        Smt.run(
          env,
          fn -> and_context(e1, e2) end,
          quote do
            assert :is_boolean.(unquote(t)) &&
                     :boolean_val.(unquote(t)) ==
                       (:boolean_val.(unquote(t1)) && :boolean_val.(unquote(t2)))
          end
        )

        {t, errors}
      end
    end
  end

  def exp(env, {fun_name, _, args}) when is_list(args) do
    arg_results = Enum.map(args, &exp(env, &1))
    arg_terms = Enum.map(arg_results, &elem(&1, 0))
    arg_errors = Enum.flat_map(arg_results, &elem(&1, 1))

    function =
      with nil <- Env.function(env, fun_name, length(arg_terms)) do
        raise EnvError,
          message: "Unspecified function #{Atom.to_string(fun_name)}/#{length(args)}"
      end

    succeed =
      function.specs
      |> Enum.reduce(Enum.empty?(function.specs), fn spec, succeed ->
        valid =
          Smt.check_valid(
            env,
            fn -> apply_context(fun_name, args) end,
            spec.pre.(arg_terms)
          )

        if valid do
          Smt.run(
            env,
            fn -> apply_context(fun_name, args) end,
            quote do
              assert unquote(spec.pre.(arg_terms))
              assert unquote(spec.post.(arg_terms))
            end
          )

          true
        else
          succeed
        end
      end)

    {
      quote(do: unquote(function.name).(unquote_splicing(arg_terms))),
      if(
        succeed,
        do: arg_errors,
        else: [
          "No precondition for #{Atom.to_string(fun_name)}/#{length(args)} holds" | arg_errors
        ]
      )
    }
  end

  def exp(_, {var_name, _, _}) do
    {var_name, []}
  end

  def exp(env, [{:|, _, [h, t]}]) do
    {head, h_errors} = exp(env, h)
    {tail, t_errors} = exp(env, t)
    list = quote(do: :cons.(unquote(head), unquote(tail)))

    Smt.run(
      env,
      fn -> list_context(h, t) end,
      quote do
        assert :is_nonempty_list.(unquote(list))
        assert :hd.(unquote(list)) == unquote(head)
        assert :tl.(unquote(list)) == unquote(tail)
      end
    )

    {list, Enum.concat(h_errors, t_errors)}
  end

  def exp(_, []) do
    {nil, []}
  end

  def exp(env, [h | t]) do
    exp(env, [{:|, [], [h, t]}])
  end

  def exp(env, literal) do
    lit_type =
      with nil <- Env.lit_type(env, literal) do
        raise EnvError,
          message: "Unknown type for literal #{Macro.to_string(literal)}"
      end

    lit = quote(do: unquote(lit_type.type_lit).(unquote(literal)))

    Smt.run(
      env,
      fn -> literal_context(literal) end,
      quote do
        assert unquote(lit_type.is_type).(unquote(lit))
        assert unquote(lit_type.type_val).(unquote(lit)) == unquote(literal)
      end
    )

    {lit, []}
  end

  @spec tuple_context([ast()]) :: String.t()
  defp tuple_context(args), do: "processing the tuple with contents #{Macro.to_string(args)}"

  @spec or_context(ast(), ast()) :: String.t()
  defp or_context(e1, e2), do: "processing #{Macro.to_string(e1)} or #{Macro.to_string(e2)}"

  @spec and_context(ast(), ast()) :: String.t()
  defp and_context(e1, e2), do: "processing #{Macro.to_string(e1)} and #{Macro.to_string(e2)}"

  @spec apply_context(atom(), [ast()]) :: String.t()
  defp apply_context(f, args), do: "processing #{Atom.to_string(f)}/#{length(args)}"

  @spec list_context(ast(), ast()) :: String.t()
  defp list_context(h, t),
    do: "processing the list with head #{Macro.to_string(h)} and tail #{Macro.to_string(t)}"

  @spec literal_context(ast()) :: String.t()
  defp literal_context(ast), do: "processing the literal #{Macro.to_string(ast)}"
end
