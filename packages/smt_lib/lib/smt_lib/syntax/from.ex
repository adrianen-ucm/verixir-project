defmodule SmtLib.Syntax.From do
  @moduledoc """
  Functions to translate a partial Elixir AST into the
  SMT-LIB syntax.
  """

  @spec command(Macro.t()) :: Macro.t()
  def command({:check_sat, _, _}) do
    quote do
      :check_sat
    end
  end

  def command({:assert, _, [t]}) do
    quote do
      {:assert, unquote(term(t))}
    end
  end

  def command({:push, _, args}) do
    n =
      case args do
        [n] -> n
        [] -> quote(do: 1)
        nil -> quote(do: 1)
      end

    quote do
      {:push, unquote(numeral(n))}
    end
  end

  def command({:pop, _, args}) do
    n =
      case args do
        [n] -> n
        [] -> quote(do: 1)
        nil -> quote(do: 1)
      end

    quote do
      {:pop, unquote(numeral(n))}
    end
  end

  def command({:declare_const, _, [[_ | _] = vs]}) do
    commands =
      for {v, s} <- vs do
        quote do
          {:declare_const, unquote(symbol(v)), unquote(sort(s))}
        end
      end

    case commands do
      [command] -> command
      commands -> commands
    end
  end

  def command({:declare_sort, _, args}) do
    [s, n] =
      case args do
        [s, n] -> [s, n]
        [s] -> [s, quote(do: 0)]
      end

    quote do
      {:declare_sort, unquote(symbol(s)), unquote(numeral(n))}
    end
  end

  def command({:declare_fun, _, [[_ | _] = fs]}) do
    commands =
      for {f, {:"::", _, [ss, s]}} <- fs do
        sort_args =
          case ss do
            {:__block__, _, sort_args} -> sort_args
            sort_arg -> [sort_arg]
          end

        quote do
          {
            :declare_fun,
            unquote(symbol(f)),
            unquote(Enum.map(sort_args, &sort(&1))),
            unquote(sort(s))
          }
        end
      end

    case commands do
      [command] -> command
      commands -> commands
    end
  end

  @spec numeral(Macro.t()) :: Macro.t()
  def numeral(n) when is_integer(n) do
    quote do
      unquote(n)
    end
  end

  @spec string(Macro.t()) :: Macro.t()
  def string(s) when is_bitstring(s) do
    quote do
      unquote(s)
    end
  end

  @spec symbol(Macro.t()) :: Macro.t()
  def symbol(s) when is_atom(s) do
    quote do
      unquote(s)
    end
  end

  def symbol({:__aliases__, _, [s]}) when is_atom(s) do
    quote do
      unquote(s)
    end
  end

  @spec sort(Macro.t()) :: Macro.t()
  def sort(s) do
    quote do
      {:sort, {:simple, unquote(symbol(s))}}
    end
  end

  @spec term(Macro.t()) :: Macro.t()
  def term(s) when is_bitstring(s) do
    quote do
      {:constant, {:string, unquote(string(s))}}
    end
  end

  def term(n) when is_integer(n) do
    quote do
      {:constant, {:numeral, unquote(numeral(n))}}
    end
  end

  def term({:forall, _, [e, vs = [_ | _]]}) do
    quote do
      {
        :forall,
        unquote(Enum.map(vs, &sorted_var(&1))),
        unquote(term(e))
      }
    end
  end

  def term({{:., _, [f]}, _, es = [_ | _]}) do
    quote do
      {
        :app,
        {:simple, unquote(symbol(f))},
        unquote(Enum.map(es, &term(&1)))
      }
    end
  end

  def term({f, _, es = [_ | _]}) when is_atom(f) do
    quote do
      {
        :app,
        {:simple, unquote(infix(f))},
        unquote(Enum.map(es, &term(&1)))
      }
    end
  end

  def term(v) do
    quote do
      {:identifier, {:simple, unquote(symbol(v))}}
    end
  end

  @spec sorted_var(Macro.t()) :: Macro.t()
  def sorted_var({v, {:__aliases__, _, [s]}}) do
    quote do
      {
        unquote(symbol(v)),
        {:sort, {:simple, unquote(symbol(s))}}
      }
    end
  end

  @spec infix(atom()) :: atom()
  [
    !: :not,
    ~>: :"=>",
    &&: :and,
    ||: :or,
    ==: :=,
    !=: :distinct,
    -: :-,
    +: :+,
    *: :*,
    <=: :<=,
    <: :<,
    >=: :>=,
    >: :>
  ]
  |> Enum.map(fn {i, s} ->
    defp infix(unquote(i)), do: unquote(s)
  end)
end
