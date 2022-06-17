defmodule SmtLib do
  @moduledoc """
  A high level API for running SMT-LIB commands written in a DSL.

  This is just `SmtLib.API` but with a DSL flavour using macros.
  """

  alias SmtLib.API
  alias SmtLib.Syntax.From
  alias SmtLib.Connection.Z3, as: Default

  @type state :: Macro.t()

  @doc """
  Runs SMT-LIB commands written in Elixir syntax as specified in
  `SmtLib.Syntax.From` and returns the result or results.

  For more details about the return value, this function is syntactic sugar for
  `SmtLib.API.run/2`.

  ## Examples

      iex> run do
      ...>   declare_sort Man
      ...>   declare_fun mortal: Man :: Bool
      ...>   assert forall :mortal.(:x), x: Man
      ...>   declare_const socrates: Man
      ...>   assert !:mortal.(:socrates)
      ...>   check_sat
      ...> end |> close()
      [:ok, :ok, :ok, :ok, :ok, {:ok, :unsat}]

  The `SmtLib.Connection` can be explicitly provided:

      iex> conn = SmtLib.Connection.Z3.new(timeout: 500)
      iex> {conn, :ok} = run conn, declare_const x: Bool
      iex> close(conn)
      :ok

  Several runs can be chained and their results are accumulated:

      iex> run do
      ...>   declare_const x: Bool
      ...>   assert :x || !:x
      ...> end
      ...> |> run(check_sat)
      ...> |> close()
      [:ok, :ok, {:ok, :sat}]

  """
  @spec run(From.ast()) :: Macro.t()
  @spec run(state(), From.ast()) :: Macro.t()
  defmacro run(state \\ default_state(), ast) do
    quote do
      API.run(
        unquote(state),
        unquote(Macro.escape(ast))
      )
    end
  end

  @spec with_local_conn(Macro.t()) :: Macro.t()
  defmacro with_local_conn(do: body) do
    quote do
      with_conn(
        unquote(default_state()),
        do: unquote(body)
      )
      |> close()
    end
  end

  @spec with_conn(Macro.t(), Macro.t()) :: Macro.t()
  defmacro with_conn(conn, do: body) do
    quote do
      conn = unquote(conn)

      result =
        unquote(
          Macro.prewalk(body, fn
            {:check_sat, meta, a} when is_atom(a) -> {:check_sat, meta, [quote(do: conn)]}
            {:check_sat, meta, []} -> {:check_sat, meta, [quote(do: conn)]}
            {:assert, meta, [ast]} -> {:assert, meta, [quote(do: conn), ast]}
            {:push, meta, a} when is_atom(a) -> {:push, meta, [quote(do: conn)]}
            {:push, meta, []} -> {:push, meta, [quote(do: conn)]}
            {:push, meta, [ast]} -> {:push, meta, [quote(do: conn), ast]}
            {:pop, meta, a} when is_atom(a) -> {:pop, meta, [quote(do: conn)]}
            {:pop, meta, []} -> {:pop, meta, [quote(do: conn)]}
            {:pop, meta, [ast]} -> {:pop, meta, [quote(do: conn), ast]}
            {:declare_const, meta, [ast]} -> {:declare_const, meta, [quote(do: conn), ast]}
            {:declare_sort, meta, [ast]} -> {:declare_sort, meta, [quote(do: conn), ast]}
            {:declare_fun, meta, [ast]} -> {:declare_fun, meta, [quote(do: conn), ast]}
            {:define_fun, meta, [ast]} -> {:define_fun, meta, [quote(do: conn), ast]}
            {:with_conn, _, _} = nested -> Macro.expand_once(nested, __CALLER__)
            other -> other
          end)
        )

      {conn, result}
    end
  end

  @spec check_sat(Macro.t()) :: Macro.t()
  defmacro check_sat(conn) do
    quote do
      API.run(
        unquote(conn),
        quote(do: check_sat)
      )
      |> elem(1)
    end
  end

  @spec assert(Macro.t(), Macro.t()) :: Macro.t()
  defmacro assert(conn, ast) do
    quote do
      ast = unquote(Macro.escape(ast))

      API.run(
        unquote(conn),
        quote(do: assert(unquote(ast)))
      )
      |> elem(1)
    end
  end

  @spec push(Macro.t()) :: Macro.t()
  defmacro push(conn) do
    quote do
      API.run(
        unquote(conn),
        quote(do: push)
      )
      |> elem(1)
    end
  end

  @spec push(Macro.t(), Macro.t()) :: Macro.t()
  defmacro push(conn, ast) do
    quote do
      ast = unquote(Macro.escape(ast))

      API.run(
        unquote(conn),
        quote(do: push(unquote(ast)))
      )
      |> elem(1)
    end
  end

  @spec pop(Macro.t()) :: Macro.t()
  defmacro pop(conn) do
    quote do
      API.run(
        unquote(conn),
        quote(do: pop)
      )
      |> elem(1)
    end
  end

  @spec pop(Macro.t(), Macro.t()) :: Macro.t()
  defmacro pop(conn, ast) do
    quote do
      ast = unquote(Macro.escape(ast))

      API.run(
        unquote(conn),
        quote(do: pop(unquote(ast)))
      )
      |> elem(1)
    end
  end

  @spec declare_const(Macro.t(), Macro.t()) :: Macro.t()
  defmacro declare_const(conn, ast) do
    quote do
      ast = unquote(Macro.escape(ast))

      API.run(
        unquote(conn),
        quote(do: declare_const(unquote(ast)))
      )
      |> elem(1)
    end
  end

  @spec declare_sort(Macro.t(), Macro.t()) :: Macro.t()
  defmacro declare_sort(conn, ast) do
    quote do
      ast = unquote(Macro.escape(ast))

      API.run(
        unquote(conn),
        quote(do: declare_sort(unquote(ast)))
      )
      |> elem(1)
    end
  end

  @spec declare_fun(Macro.t(), Macro.t()) :: Macro.t()
  defmacro declare_fun(conn, ast) do
    quote do
      ast = unquote(Macro.escape(ast))

      API.run(
        unquote(conn),
        quote(do: declare_fun(unquote(ast)))
      )
      |> elem(1)
    end
  end

  @spec define_fun(Macro.t(), Macro.t()) :: Macro.t()
  defmacro define_fun(conn, ast) do
    quote do
      ast = unquote(Macro.escape(ast))

      API.run(
        unquote(conn),
        quote(do: define_fun(unquote(ast)))
      )
      |> elem(1)
    end
  end

  @doc """
  Closes an `SmtLib.Connection` and, when chained at the end of a
  `SmtLib.run/2` examples, it forwards the results.

  See its usage in the `SmtLib.run/2` examples. This function is a
  counterpart for `SmtLib.API.close/1`.
  """
  @spec close(state()) :: Macro.t()
  defmacro close(state) do
    quote do
      API.close(unquote(state))
    end
  end

  @spec default_state() :: state()
  defp default_state() do
    quote do
      Default.new()
    end
  end
end
