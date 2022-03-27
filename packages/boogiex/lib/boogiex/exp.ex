defmodule Boogiex.Exp do
  alias SmtLib.API
  alias Boogiex.Env
  alias Boogiex.Theory
  alias SmtLib.Syntax.From

  # TODO better error handling and pattern matching
  # TODO refactor and reduce runtime overhead

  @spec exp(Macro.t(), Macro.t()) :: {Macro.t(), Macro.t()}
  def exp(env, {fun_name, _, args}) when is_list(args) do
    quote do
      env = unquote(env)
      terms = unquote(Enum.map(args, &exp(env, &1)))
      fun_name = unquote(fun_name)

      # TODO mock, get this through env
      {corresponding_fun_name, fun_specs} = Theory.function(fun_name)

      for spec <- fun_specs do
        with {_, [:ok, :ok, {:ok, :unsat}, :ok]} <-
               API.run(
                 Env.connection(env),
                 From.commands(
                   quote do
                     push
                     assert !unquote(spec.pre.(terms))
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
                  assert unquote(spec.post.(terms))
                end
              )
            )
        end
      end

      quote do
        unquote(corresponding_fun_name).(unquote_splicing(terms))
      end
    end
  end

  def exp(_, {var_name, _, _}) do
    var_name
  end

  def exp(env, literal) do
    {is_type, type_val, type_lit, type_dec} =
      case literal do
        literal when is_integer(literal) -> {:is_integer, :integer_val, :integer_lit, :integer}
        literal when is_boolean(literal) -> {:is_boolean, :boolean_val, :boolean_lit, :boolean}
      end

    quote do
      env = unquote(env)
      literal = unquote(literal)
      is_type = unquote(is_type)
      type_val = unquote(type_val)
      type_lit = unquote(type_lit)
      type_dec = unquote(type_dec)

      {_, [:ok, :ok, :ok, :ok]} =
        API.run(
          Env.connection(env),
          From.commands(
            quote do
              assert unquote(is_type).(unquote(type_lit).(unquote(literal)))

              assert unquote(type_val).(unquote(type_lit).(unquote(literal))) ==
                       unquote(literal)

              assert :is_boolean.(unquote(type_dec).(unquote(type_lit).(unquote(literal))))
              assert :boolean_val.(unquote(type_dec).(unquote(type_lit).(unquote(literal))))
            end
          )
        )

      quote do
        unquote(type_lit).(unquote(literal))
      end
    end
  end
end
