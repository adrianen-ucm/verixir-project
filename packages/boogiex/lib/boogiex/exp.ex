defmodule Boogiex.Exp do
  alias SmtLib.API
  alias Boogiex.Env
  alias SmtLib.Syntax.From
  alias Boogiex.Error.SmtError
  alias Boogiex.Error.EnvError

  @type ast :: Macro.t()

  @spec exp(Env.t(), ast()) :: From.ast()
  def exp(env, {fun_name, _, args}) when is_list(args) do
    arg_terms = Enum.map(args, &exp(env, &1))

    function =
      with nil <- Env.function(env, fun_name, length(arg_terms)) do
        f = Atom.to_string(fun_name)
        a = length(arg_terms)

        raise EnvError,
          message: "Unspecified function #{f}/#{a}"
      end

    for spec <- function.specs do
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
              context: "checking the #{f}/#{a} postconditions"
        end
      end
    end

    quote do
      unquote(function.name).(unquote_splicing(arg_terms))
    end
  end

  def exp(_, {var_name, _, _}) do
    var_name
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

    quote do
      unquote(lit_type.type_lit).(unquote(literal))
    end
  end
end
