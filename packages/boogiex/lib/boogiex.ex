defmodule Boogiex do
  alias SmtLib.API
  alias Boogiex.Exp
  alias Boogiex.Env
  alias SmtLib.Syntax.From
  alias SmtLib.Connection.Z3, as: Default

  # TODO better error handling and pattern matching
  # TODO refactor and reduce runtime overhead

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
      term = unquote(Exp.exp(quote(do: env), name))

      {_, :ok} =
        API.run(
          Env.connection(env),
          From.commands(
            quote do
              declare_const [{unquote(term), Term}]
            end
          )
        )

      :ok
    end
  end

  @spec assume(Macro.t(), Macro.t()) :: Macro.t()
  defmacro assume(env, ast) do
    quote do
      env = unquote(env)
      term = unquote(Exp.exp(quote(do: env), ast))

      {_, [:ok, :ok, {:ok, result}, :ok, :ok]} =
        API.run(
          Env.connection(env),
          From.commands(
            quote do
              push
              assert !:is_boolean.(unquote(term))
              check_sat
              pop
              assert :boolean_val.(unquote(term))
            end
          )
        )

      case result do
        :unsat ->
          :ok

        _ ->
          error = {:error, :assume_failed}
          Env.error(env, error)
          error
      end
    end
  end

  @spec assert(Macro.t(), Macro.t()) :: Macro.t()
  @spec assert(Macro.t(), Macro.t(), Macro.t()) :: Macro.t()
  defmacro assert(env, ast, error_payload \\ :assert_failed) do
    quote do
      env = unquote(env)
      term = unquote(Exp.exp(quote(do: env), ast))

      with {_, [:ok, :ok, {:ok, :unsat}, :ok]} <-
             API.run(
               Env.connection(env),
               From.commands(
                 quote do
                   push
                   assert !:is_boolean.(unquote(term))
                   check_sat
                   pop
                 end
               )
             ),
           # TODO shortcircuit or always continue?
           {_, [:ok, :ok, {:ok, :unsat}, :ok, :ok]} <-
             API.run(
               Env.connection(env),
               From.commands(
                 quote do
                   push
                   assert !:boolean_val.(unquote(term))
                   check_sat
                   pop
                   assert :boolean_val.(unquote(term))
                 end
               )
             ) do
        :ok
      else
        _ ->
          error = {:error, unquote(error_payload)}
          Env.error(env, error)
          error
      end
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

  @spec default_env() :: Macro.t()
  defp default_env() do
    quote do
      Default.new()
      |> Env.new()
    end
  end
end
