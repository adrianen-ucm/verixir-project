defmodule Boogiex.Exp do
  alias SmtLib.API
  alias Boogiex.Env
  alias SmtLib.Syntax.From
  alias Boogiex.Error.SmtError
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

    {_, [result_1, result_2]} =
      API.run(
        Env.connection(env),
        From.commands(
          quote do
            assert :is_tuple.(unquote(term))
            assert :tuple_size.(unquote(term)) == unquote(n)
          end
        )
      )

    {_, results} =
      API.run(
        Env.connection(env),
        arg_terms
        |> Enum.with_index(fn element, index ->
          quote(do: assert(:elem.(unquote(term), unquote(index)) == unquote(element)))
        end)
        |> From.commands()
      )

    for result <- [result_1, result_2 | List.wrap(results)] do
      with {:error, e} <- result do
        raise SmtError,
          error: e,
          context: "processing the tuple with contents #{Macro.to_string(args)}"
      end
    end

    {
      term,
      arg_errors
    }
  end

  def exp(env, {fun_name, _, args}) when is_list(args) do
    arg_results = Enum.map(args, &exp(env, &1))
    arg_terms = Enum.map(arg_results, &elem(&1, 0))
    arg_errors = Enum.flat_map(arg_results, &elem(&1, 1))

    function =
      with nil <- Env.function(env, fun_name, length(arg_terms)) do
        f = Atom.to_string(fun_name)
        a = length(arg_terms)

        raise EnvError,
          message: "Unspecified function #{f}/#{a}"
      end

    succeed =
      function.specs
      |> Enum.reduce(Enum.empty?(function.specs), fn spec, succeed ->
        {_, [push_result, assert_result, sat_result, pop_result]} =
          API.run(
            Env.connection(env),
            From.commands(
              quote do
                push
                assert !unquote(spec.pre.(arg_terms))
                check_sat
                pop
              end
            )
          )

        sat_result =
          with :ok <- push_result,
               :ok <- assert_result,
               {:ok, sat_result} <- sat_result,
               :ok <- pop_result do
            sat_result
          else
            {:error, e} ->
              f = Atom.to_string(fun_name)
              a = length(arg_terms)

              raise SmtError,
                error: e,
                context: "checking the #{f}/#{a} preconditions"
          end

        with :unsat <- sat_result do
          {_, [assert_pre_result, assert_post_result]} =
            API.run(
              Env.connection(env),
              From.commands(
                quote do
                  assert unquote(spec.pre.(arg_terms))
                  assert unquote(spec.post.(arg_terms))
                end
              )
            )

          with :ok <- assert_pre_result,
               :ok <- assert_post_result do
          else
            {:error, e} ->
              f = Atom.to_string(fun_name)
              a = length(arg_terms)

              raise SmtError,
                error: e,
                context: "assuming the #{f}/#{a} postconditions"
          end

          true
        else
          _ -> succeed
        end
      end)

    {
      quote(do: unquote(function.name).(unquote_splicing(arg_terms))),
      if succeed do
        arg_errors
      else
        f = Atom.to_string(fun_name)
        a = length(arg_terms)
        ["No precondition for #{f}/#{a} holds" | arg_errors]
      end
    }
  end

  def exp(_, {var_name, _, _}) do
    {
      var_name,
      []
    }
  end

  def exp(env, l) when is_list(l) do
    {t, errors, _} =
      List.foldr(
        l,
        {nil, [], 0},
        fn e, {tail, tail_errors, tail_n} ->
          {head, head_errors} = exp(env, e)

          list_n = tail_n + 1
          list = quote(do: :cons.(unquote(head), unquote(tail)))

          {_, results} =
            API.run(
              Env.connection(env),
              From.commands(
                quote do
                  assert :is_list.(unquote(list))
                  assert :length.(unquote(list)) == unquote(list_n)
                  assert :hd.(unquote(list)) == unquote(head)
                  assert :tl.(unquote(list)) == unquote(tail)
                end
              )
            )

          for r <- results do
            with {:error, e} <- r do
              raise SmtError,
                error: e,
                context: "processing the list with contents #{Macro.to_string(l)}"
            end
          end

          {
            quote(do: :cons.(unquote(head), unquote(tail))),
            [head_errors | tail_errors],
            list_n
          }
        end
      )

    {t, List.flatten(errors)}
  end

  def exp(env, literal) do
    lit_type =
      with nil <- Env.lit_type(env, literal) do
        raise EnvError,
          message: "Unknown type for literal #{Macro.to_string(literal)}"
      end

    {_, [result_1, result_2]} =
      API.run(
        Env.connection(env),
        From.commands(
          quote do
            assert unquote(lit_type.is_type).(unquote(lit_type.type_lit).(unquote(literal)))

            assert unquote(lit_type.type_val).(unquote(lit_type.type_lit).(unquote(literal))) ==
                     unquote(literal)
          end
        )
      )

    with :ok <- result_1,
         :ok <- result_2 do
    else
      {:error, e} ->
        raise SmtError,
          error: e,
          context: "processing the literal #{Macro.to_string(literal)}"
    end

    {
      quote(do: unquote(lit_type.type_lit).(unquote(literal))),
      []
    }
  end
end
