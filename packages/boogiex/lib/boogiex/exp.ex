defmodule Boogiex.Exp do
  alias SmtLib.API
  alias Boogiex.Env
  alias SmtLib.Syntax.From

  @type ast :: Macro.t()

  # TODO transform unmatched patterns into error data?
  # I'm going to annotate errors which maybe should be reported

  @spec exp(Env.t(), ast()) :: From.ast()
  def exp(env, {fun_name, _, args}) when is_list(args) do
    # TODO nested exp can report errors
    arg_terms = Enum.map(args, &exp(env, &1))

    # TODO can be nil
    {corresponding_fun_name, fun_specs} = Env.function(env, fun_name)

    for spec <- fun_specs do
      # TODO maybe the assert :ok is an error
      {_, [:ok, :ok, {:ok, result}, :ok]} =
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

      with :unsat <- result do
        # TODO maybe the assert :ok is an error
        {_, :ok} =
          API.run(
            Env.connection(env),
            From.commands(
              quote do
                assert unquote(spec.post.(arg_terms))
              end
            )
          )
      end
    end

    quote do
      unquote(corresponding_fun_name).(unquote_splicing(arg_terms))
    end
  end

  def exp(_, {var_name, _, _}) do
    var_name
  end

  def exp(env, literal) do
    # TODO can be nil
    {is_type, type_val, type_lit} = Env.literal(env, literal)

    {_, [:ok, :ok]} =
      API.run(
        Env.connection(env),
        From.commands(
          quote do
            assert unquote(is_type).(unquote(type_lit).(unquote(literal)))

            assert unquote(type_val).(unquote(type_lit).(unquote(literal))) ==
                     unquote(literal)
          end
        )
      )

    quote do
      unquote(type_lit).(unquote(literal))
    end
  end
end
