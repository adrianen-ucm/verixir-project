defmodule Boogiex.Exp do
  alias SmtLib.API
  alias Boogiex.Env
  alias Boogiex.Theory
  alias SmtLib.Syntax.From

  @type ast :: Macro.t()

  # TODO better error handling and pattern matching

  @spec exp(Env.t(), ast()) :: From.ast()
  def exp(env, {fun_name, _, args}) when is_list(args) do
    arg_terms = Enum.map(args, &exp(env, &1))

    # TODO mock, get this through env
    {corresponding_fun_name, fun_specs} = Theory.function(fun_name)

    for spec <- fun_specs do
      with {_, [:ok, :ok, {:ok, :unsat}, :ok]} <-
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
             ) do
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
    {is_type, type_val, type_lit} =
      case literal do
        literal when is_integer(literal) -> {:is_integer, :integer_val, :integer_lit}
        literal when is_boolean(literal) -> {:is_boolean, :boolean_val, :boolean_lit}
      end

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
