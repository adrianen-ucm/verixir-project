defmodule Boogiex do
  require SmtLib
  alias Boogiex.Env, as: E
  alias Boogiex.Theory, as: T
  alias SmtLib.Syntax.From, as: F

  @spec with_env(Macro.t(), Macro.t()) :: Macro.t()
  defmacro with_env(env \\ default_env(), do: body) do
    quote do
      env = unquote(env)

      result =
        unquote(
          Macro.prewalk(body, fn
            {:havoc, meta, [name]} -> {:havoc, meta, [quote(do: env), name]}
            {:assume, meta, [ast]} -> {:assume, meta, [quote(do: env), ast]}
            {:assert, meta, [ast]} -> {:assert, meta, [quote(do: env), ast]}
            {:assert, meta, [ast, error]} -> {:assert, meta, [quote(do: env), ast, error]}
            {:with_env, _, _} = nested -> Macro.expand_once(nested, __CALLER__)
            other -> other
          end)
        )

      {env, result}
    end
  end

  @spec havoc(Macro.t(), Macro.t()) :: Macro.t()
  defmacro havoc(env, name) do
    quote do
      env = unquote(env)

      {_, result} =
        unquote(
          Macro.expand_once(
            quote do
              SmtLib.run(
                E.connection(env),
                declare_const([{unquote(name), Term}])
              )
            end,
            __ENV__
          )
        )

      with {:error, e} <- result do
        E.error(env, e)
      end

      result
    end
  end

  @spec assume(Macro.t(), Macro.t()) :: Macro.t()
  defmacro assume(env, ast) do
    quote do
      env = unquote(env)

      {_, result} =
        unquote(
          Macro.expand_once(
            quote do
              SmtLib.run(
                E.connection(env),
                assert(unquote(ast))
              )
            end,
            __ENV__
          )
        )

      with {:error, e} <- result do
        E.error(unquote(env), e)
      end

      result
    end
  end

  @spec assert(Macro.t(), Macro.t()) :: Macro.t()
  @spec assert(Macro.t(), Macro.t(), Macro.t()) :: Macro.t()
  defmacro assert(env, ast, error_payload \\ :assert_failed) do
    quote do
      env = unquote(env)

      {_, results} =
        unquote(
          Macro.expand_once(
            quote do
              SmtLib.run E.connection(env) do
                push
                unquote(F.term(ast) |> T.for_term())
                assert !unquote(ast)
                check_sat
                pop
                assert unquote(ast)
              end
            end,
            __ENV__
          )
        )

      errors =
        Enum.reduce(results, [], fn
          {:error, e}, errors -> [e | errors]
          {:ok, :sat}, errors -> [{:error, unquote(error_payload)} | errors]
          {:ok, :unknown}, errors -> [{:error, unquote(error_payload)} | errors]
          _, errors -> errors
        end)

      Enum.each(errors, &E.error(unquote(env), &1))

      case errors do
        [] -> :ok
        errors -> {:error, errors}
      end
    end
  end

  @spec clear(Macro.t()) :: Macro.t()
  defmacro clear(result) do
    quote do
      case unquote(result) do
        {env, result} ->
          Boogiex.Env.clear(env)
          result

        env ->
          Boogiex.Env.clear(env)
          :ok
      end
    end
  end

  @spec default_env() :: Macro.t()
  defp default_env() do
    quote do
      SmtLib.Connection.Z3.new()
      |> Boogiex.Env.new()
    end
  end
end
