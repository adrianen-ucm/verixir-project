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

    {corresponding_fun_name, fun_specs} =
      with nil <- Env.function(env, fun_name, length(arg_terms)) do
        raise EnvError, message: "Undefined function #{fun_name}"
      end

    for spec <- fun_specs do
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
          {:error, e} -> raise SmtError, error: e
        end

      with :unsat <- sat_result do
        {_, assert_result} =
          API.run(
            Env.connection(env),
            From.commands(
              quote do
                assert unquote(spec.post.(arg_terms))
              end
            )
          )

        with {:error, e} <- assert_result do
          raise SmtError, error: e
        end
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
      with nil <- Env.literal(env, literal) do
        raise EnvError, message: "Unknown type for literal #{literal}"
      end

    {_, [result_1, result_2]} =
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

    with :ok <- result_1,
         :ok <- result_2 do
    else
      {:error, e} -> raise SmtError, error: e
    end

    quote do
      unquote(type_lit).(unquote(literal))
    end
  end
end
