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
      env =
        Default.new()
        |> Env.new(unquote(config))

      result =
        with_env(
          env,
          do: unquote(body)
        )

      clear(env)
      result
    end
  end

  @spec with_env(env(), Macro.t()) :: Macro.t()
  defmacro with_env(env, do: body) do
    quote do
      env = unquote(env)

      unquote(
        Macro.traverse(
          body,
          0,
          fn
            {:havoc, meta, [name]}, 0 ->
              {{:havoc, meta, [quote(do: env), name]}, 0}

            {:assume, meta, [ast]}, 0 ->
              {{:assume, meta, [quote(do: env), ast]}, 0}

            {:assume, meta, [ast, error]}, 0 ->
              {{:assume, meta, [quote(do: env), ast, error]}, 0}

            {:assert, meta, [ast]}, 0 ->
              {{:assert, meta, [quote(do: env), ast]}, 0}

            {:assert, meta, [ast, error]}, 0 ->
              {{:assert, meta, [quote(do: env), ast, error]}, 0}

            {:block, meta, [body]}, 0 ->
              {{:block, meta, [quote(do: env), body]}, 0}

            {:with_local_env, _, _} = ast, n ->
              {ast, n + 1}

            {:with_env, _, _} = ast, n ->
              {ast, n + 1}

            other, n ->
              {other, n}
          end,
          fn
            {:with_local_env, _, _} = ast, n -> {ast, n - 1}
            {:with_env, _, _} = ast, n -> {ast, n - 1}
            other, n -> {other, n}
          end
        )
      )
      |> elem(0)
    end
  end

  @spec havoc(env(), L1Exp.ast()) :: Macro.t()
  defmacro havoc(env, ast) do
    quote do
      L1Stm.eval(
        unquote(env),
        unquote(
          Macro.escape(
            quote do
              havoc unquote(ast)
            end
          )
        )
      )
    end
  end

  @spec assume(env(), L1Exp.ast()) :: Macro.t()
  @spec assume(env(), L1Exp.ast(), Macro.t()) :: Macro.t()
  defmacro assume(env, ast, error_msg \\ nil) do
    error_msg =
      with nil <- error_msg do
        Msg.assume_failed(ast)
      end

    quote do
      L1Stm.eval(
        unquote(env),
        unquote(
          Macro.escape(
            quote do
              assume unquote(ast), unquote(error_msg)
            end
          )
        )
      )
    end
  end

  @spec assert(env(), L1Exp.ast()) :: Macro.t()
  @spec assert(env(), L1Exp.ast(), Macro.t()) :: Macro.t()
  defmacro assert(env, ast, error_msg \\ nil) do
    error_msg =
      with nil <- error_msg do
        Msg.assert_failed(ast)
      end

    quote do
      L1Stm.eval(
        unquote(env),
        unquote(
          Macro.escape(
            quote do
              assert unquote(ast), unquote(error_msg)
            end
          )
        )
      )
    end
  end

  @spec block(env(), Macro.t()) :: Macro.t()
  defmacro block(env, do: body) do
    quote do
      env = unquote(env)

      tuple_constructor = Env.tuple_constructor(env)

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

      Env.update_tuple_constructor(env, tuple_constructor)
    end
  end

  @spec clear(Macro.t()) :: Macro.t()
  defmacro clear(env) do
    quote do
      Env.clear(unquote(env))
    end
  end
end
