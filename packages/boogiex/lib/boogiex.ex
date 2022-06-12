defmodule Boogiex do
  alias Boogiex.Env
  alias Boogiex.Msg
  alias Boogiex.Lang.L1Exp
  alias Boogiex.Lang.L1Stm
  alias SmtLib.Connection.Z3, as: Default

  @type env :: Macro.t()
  @type config :: Macro.t()

  @spec with_local_env(config(), Macro.t()) :: Macro.t()
  defmacro with_local_env(config \\ [], do: body) do
    quote do
      with_env(
        Default.new()
        |> Env.new(unquote(config)),
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
            {:assume, meta, [ast, error]} -> {:assume, meta, [quote(do: env), ast, error]}
            {:assert, meta, [ast]} -> {:assert, meta, [quote(do: env), ast]}
            {:assert, meta, [ast, error]} -> {:assert, meta, [quote(do: env), ast, error]}
            {:block, meta, [body]} -> {:block, meta, [quote(do: env), body]}
            {:unfold, meta, [ast]} -> {:unfold, meta, [quote(do: env), ast]}
            {:with_env, _, _} = nested -> Macro.expand_once(nested, __CALLER__)
            other -> other
          end)
        )

      {env, result}
    end
  end

  @spec havoc(env(), L1Exp.ast()) :: Macro.t()
  defmacro havoc(env, ast) do
    quote do
      L1Stm.havoc(
        unquote(env),
        unquote(Macro.escape(ast))
      )
    end
  end

  @spec assume(env(), L1Exp.ast()) :: Macro.t()
  @spec assume(env(), L1Exp.ast(), Macro.t()) :: Macro.t()
  defmacro assume(env, ast, error_msg \\ quote(do: Msg.assume_failed())) do
    quote do
      L1Stm.assume(
        unquote(env),
        unquote(Macro.escape(ast)),
        unquote(error_msg)
      )
    end
  end

  @spec assert(env(), L1Exp.ast()) :: Macro.t()
  @spec assert(env(), L1Exp.ast(), Macro.t()) :: Macro.t()
  defmacro assert(env, ast, error_msg \\ quote(do: Msg.assert_failed())) do
    quote do
      L1Stm.assert(
        unquote(env),
        unquote(Macro.escape(ast)),
        unquote(error_msg)
      )
    end
  end

  @spec block(env(), Macro.t()) :: Macro.t()
  defmacro block(env, do: body) do
    quote do
      env = unquote(env)

      Boogiex.Lang.SmtLib.run(
        Env.connection(env),
        Msg.block_context(),
        quote(do: push)
      )

      unquote(body)

      Boogiex.Lang.SmtLib.run(
        Env.connection(env),
        Msg.block_context(),
        quote(do: pop)
      )
    end
  end

  @spec unfold(env(), Macro.t()) :: Macro.t()
  defmacro unfold(env, {f, _, args}) do
    quote do
      L1Stm.unfold(
        unquote(env),
        unquote(Macro.escape(f)),
        unquote(Macro.escape(args))
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
