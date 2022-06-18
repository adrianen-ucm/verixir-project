defmodule SmtLib do
  @moduledoc """
  A high level API for running SMT-LIB commands written in a DSL.

  This is just `SmtLib.API` but with a DSL flavour using macros.
  """

  alias SmtLib.API
  alias SmtLib.Syntax.From
  alias SmtLib.Connection.Z3, as: Default

  @type conn :: Macro.t()

  @spec with_local_conn(Macro.t()) :: Macro.t()
  defmacro with_local_conn(do: body) do
    quote do
      conn = Default.new()

      result =
        with_conn(
          conn,
          do: unquote(body)
        )

      close(conn)
      result
    end
  end

  @spec with_conn(conn(), Macro.t()) :: Macro.t()
  defmacro with_conn(conn, do: body) do
    quote do
      conn = unquote(conn)

      unquote(
        Macro.traverse(
          body,
          0,
          fn
            {:check_sat, meta, a}, 0 when is_atom(a) ->
              {{:check_sat, meta, [quote(do: conn)]}, 0}

            {:check_sat, meta, []}, 0 ->
              {{:check_sat, meta, [quote(do: conn)]}, 0}

            {:assert, meta, [ast]}, 0 ->
              {{:assert, meta, [quote(do: conn), ast]}, 0}

            {:push, meta, a}, 0 when is_atom(a) ->
              {{:push, meta, [quote(do: conn)]}, 0}

            {:push, meta, []}, 0 ->
              {{:push, meta, [quote(do: conn)]}, 0}

            {:push, meta, [ast]}, 0 ->
              {{:push, meta, [quote(do: conn), ast]}, 0}

            {:pop, meta, a}, 0 when is_atom(a) ->
              {{:pop, meta, [quote(do: conn)]}, 0}

            {:pop, meta, []}, 0 ->
              {{:pop, meta, [quote(do: conn)]}, 0}

            {:pop, meta, [ast]}, 0 ->
              {{:pop, meta, [quote(do: conn), ast]}, 0}

            {:declare_const, meta, [ast]}, 0 ->
              {{:declare_const, meta, [quote(do: conn), ast]}, 0}

            {:declare_sort, meta, [ast]}, 0 ->
              {{:declare_sort, meta, [quote(do: conn), ast]}, 0}

            {:declare_fun, meta, [ast]}, 0 ->
              {{:declare_fun, meta, [quote(do: conn), ast]}, 0}

            {:define_fun, meta, [ast]}, 0 ->
              {{:define_fun, meta, [quote(do: conn), ast]}, 0}

            {:with_local_conn, _, _} = ast, n ->
              {ast, n + 1}

            {:with_conn, _, _} = ast, n ->
              {ast, n + 1}

            other, n ->
              {other, n}
          end,
          fn
            {:with_conn, _, _} = ast, n -> {ast, n - 1}
            {:with_local_conn, _, _} = ast, n -> {ast, n - 1}
            other, n -> {other, n}
          end
        )
      )
      |> elem(0)
    end
  end

  @spec check_sat(conn()) :: Macro.t()
  defmacro check_sat(conn) do
    quote do
      API.run(
        unquote(conn),
        unquote(
          From.commands(
            quote do
              check_sat
            end
          )
        )
      )
    end
  end

  @spec assert(conn(), From.ast()) :: Macro.t()
  defmacro assert(conn, ast) do
    quote do
      API.run(
        unquote(conn),
        unquote(
          From.commands(
            quote do
              assert unquote(ast)
            end
          )
        )
      )
    end
  end

  @spec push(conn()) :: Macro.t()
  defmacro push(conn) do
    quote do
      API.run(
        unquote(conn),
        unquote(
          From.commands(
            quote do
              push
            end
          )
        )
      )
    end
  end

  @spec push(conn(), From.ast()) :: Macro.t()
  defmacro push(conn, ast) do
    quote do
      API.run(
        unquote(conn),
        unquote(
          From.commands(
            quote do
              push unquote(ast)
            end
          )
        )
      )
    end
  end

  @spec pop(conn()) :: Macro.t()
  defmacro pop(conn) do
    quote do
      API.run(
        unquote(conn),
        unquote(
          From.commands(
            quote do
              pop
            end
          )
        )
      )
    end
  end

  @spec pop(conn(), From.ast()) :: Macro.t()
  defmacro pop(conn, ast) do
    quote do
      API.run(
        unquote(conn),
        unquote(
          From.commands(
            quote do
              pop unquote(ast)
            end
          )
        )
      )
    end
  end

  @spec declare_const(conn(), From.ast()) :: Macro.t()
  defmacro declare_const(conn, ast) do
    quote do
      API.run(
        unquote(conn),
        unquote(
          From.commands(
            quote do
              declare_const unquote(ast)
            end
          )
        )
      )
    end
  end

  @spec declare_sort(conn(), From.ast()) :: Macro.t()
  defmacro declare_sort(conn, ast) do
    quote do
      API.run(
        unquote(conn),
        unquote(
          From.commands(
            quote do
              declare_sort unquote(ast)
            end
          )
        )
      )
    end
  end

  @spec declare_fun(conn(), From.ast()) :: Macro.t()
  defmacro declare_fun(conn, ast) do
    quote do
      API.run(
        unquote(conn),
        unquote(
          From.commands(
            quote do
              declare_fun unquote(ast)
            end
          )
        )
      )
    end
  end

  @spec define_fun(conn(), From.ast()) :: Macro.t()
  defmacro define_fun(conn, ast) do
    quote do
      ast = unquote(Macro.escape(ast))

      API.run(
        unquote(conn),
        unquote(
          From.commands(
            quote do
              define_fun unquote(ast)
            end
          )
        )
      )
    end
  end

  @spec close(conn()) :: Macro.t()
  defmacro close(conn) do
    quote do
      API.close(unquote(conn))
    end
  end
end
