defmodule Boogiex do
  alias Boogiex.Stm
  alias Boogiex.Env
  alias Boogiex.Exp
  alias SmtLib.Connection.Z3, as: Default

  @type env :: Macro.t()

  @spec with_env(Macro.t()) :: Macro.t()
  defmacro with_env(do: body) do
    quote do
      with_env(
        Default.new()
        |> Env.new(),
        do: unquote(body)
      )
      |> clear()
    end
  end

  @spec with_env(env(), Macro.t()) :: Macro.t()
  defmacro with_env(env, do: body) do
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

  @spec havoc(env(), Exp.ast()) :: Macro.t()
  defmacro havoc(env, ast) do
    quote do
      Stm.havoc(
        unquote(env),
        unquote(Macro.escape(ast))
      )
    end
  end

  @spec assume(env(), Exp.ast()) :: Macro.t()
  defmacro assume(env, ast) do
    quote do
      Stm.assume(
        unquote(env),
        unquote(Macro.escape(ast))
      )
    end
  end

  @spec assert(env(), Exp.ast()) :: Macro.t()
  @spec assert(env(), Exp.ast(), Macro.t()) :: Macro.t()
  defmacro assert(env, ast, error_payload \\ :assert_failed) do
    quote do
      Stm.assert(
        unquote(env),
        unquote(Macro.escape(ast)),
        unquote(error_payload)
      )
    end
  end

  @spec clear(Macro.t()) :: Macro.t()
  defmacro clear(result) do
    quote do
      case unquote(result) do
        {env, result} ->
          Env.clear(env)
          result

        env ->
          Env.clear(env)
          :ok
      end
    end
  end
end
