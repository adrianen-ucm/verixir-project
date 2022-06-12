# Example of a simple language implemented on top of SmtLib

# The language L0
defmodule L0 do
  import SmtLib

  defmacro init(conn) do
    quote do
      run(unquote(conn)) do
        declare_sort Term
      end
    end
  end

  defmacro eval(_, {:skip, _, _}) do
    quote do
      nil
    end
  end

  defmacro eval(_, {:fail, _, _}) do
    quote do
      raise "Verification failed"
    end
  end

  defmacro eval(conn, {:seq, _, [e1, e2]}) do
    quote do
      conn = unquote(conn)
      eval(conn, unquote(e1))
      eval(conn, unquote(e2))
    end
  end

  defmacro eval(conn, {:local, _, [e]}) do
    quote do
      conn = unquote(conn)
      {_, :ok} = run(conn, push)
      eval(conn, unquote(e))
      {_, :ok} = run(conn, pop)
    end
  end

  defmacro eval(conn, {:add, _, [f]}) do
    quote do
      conn = unquote(conn)
      {_, :ok} = run(conn, assert(unquote(f)))
    end
  end

  defmacro eval(conn, {:declare_const, _, [x]}) do
    quote do
      conn = unquote(conn)
      {_, :ok} = run(conn, declare_const([{unquote(x), Term}]))
    end
  end

  defmacro eval(conn, {:when_unsat, _, [e1, [do: e2, else: e3]]}) do
    quote do
      conn = unquote(conn)
      {_, :ok} = run(conn, push)
      eval(conn, unquote(e1))
      {_, {:ok, result}} = run(conn, check_sat)
      {_, :ok} = run(conn, pop)

      case result do
        :unsat -> eval(conn, unquote(e2))
        _ -> eval(conn, unquote(e3))
      end
    end
  end

  defmacro eval(_, other) do
    raise "Unknown L0 expression #{Macro.to_string(other)}"
  end
end

# Example using L0
defmodule Main do
  alias SmtLib.Connection, as: C
  alias SmtLib.Connection.Z3

  import L0

  def main() do
    conn = Z3.new()

    init(conn)

    eval(
      conn,
      when_unsat seq(
                   declare_const(:x),
                   # Succeeds
                   add(:x != :x)
                   # Fails
                   # add(:x == :x)
                 ) do
        skip
      else
        fail
      end
    )

    C.close(conn)
  end
end

Main.main()
