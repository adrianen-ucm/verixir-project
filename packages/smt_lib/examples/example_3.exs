# Example of a simple language implemented on top of SmtLib

# The language L0
defmodule L0 do
  import SmtLib

  defmacro init(conn) do
    quote do
      :ok = declare_sort unquote(conn), Term
    end
  end

  defmacro eval(_, {:skip, _, _}) do
    nil
  end

  defmacro eval(_, {:fail, _, _}) do
    quote do
      raise "Verification failed"
    end
  end

  defmacro eval(conn, {:local, _, [e]}) do
    quote do
      conn = unquote(conn)
      :ok = push conn
      eval conn, unquote(e)
      :ok = pop conn
    end
  end

  defmacro eval(conn, {:add, _, [f]}) do
    quote do
      :ok = assert unquote(conn), unquote(f)
    end
  end

  defmacro eval(conn, {:declare_const, _, [x]}) do
    quote do
      :ok = declare_const unquote(conn), [{unquote(x), Term}]
    end
  end

  defmacro eval(conn, {:when_unsat, _, [e1, [do: e2, else: e3]]}) do
    quote do
      conn = unquote(conn)
      :ok = push conn
      eval conn, unquote(e1)
      {:ok, result} = check_sat(conn)
      :ok = pop conn

      case result do
        :unsat -> eval conn, unquote(e2)
        _ -> eval conn, unquote(e3)
      end
    end
  end

  defmacro eval(conn, {:__block__, _, [e | es]}) do
    quote do
      conn = unquote(conn)
      eval conn, unquote(e)
      eval conn, unquote({:__block__, [], es})
    end
  end

  defmacro eval(_, {:__block__, _, []}) do
    nil
  end

  defmacro eval(conn, do: e) do
    quote do
      conn = unquote(conn)
      eval conn, unquote(e)
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

    eval conn do
      declare_const :x

      # Replace '!=' by '==' to fail
      when_unsat add :x != :x do
        skip
      else
        fail
      end
    end

    C.close(conn)
  end
end

Main.main()
