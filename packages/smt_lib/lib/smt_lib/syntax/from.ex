defmodule SmtLib.Syntax.From do
  @moduledoc """
  Functions to translate a partial Elixir AST into the
  SMT-LIB syntax.
  """

  alias SmtLib.Syntax, as: S

  @spec command(Macro.t()) :: S.command_t()
  def command({:check_sat, _, _}) do
    :check_sat
  end

  def command({:assert, _, [t]}) do
    {:assert, term(t)}
  end

  def command({:push, _, args}) do
    n =
      case args do
        [n] -> n
        [] -> 1
        a when is_atom(a) -> 1
      end

    {:push, numeral(n)}
  end

  def command({:pop, _, args}) do
    n =
      case args do
        [n] -> n
        [] -> 1
        a when is_atom(a) -> 1
      end

    {:pop, numeral(n)}
  end

  def command({:declare_const, _, [[_ | _] = vs]}) do
    commands =
      for {v, s} <- vs do
        {:declare_const, symbol(v), sort(s)}
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
        [s] -> [s, 0]
      end

    {:declare_sort, symbol(s), numeral(n)}
  end

  def command({:declare_fun, _, [[_ | _] = fs]}) do
    commands =
      for {f, {:"::", _, [ss, s]}} <- fs do
        sort_args =
          case ss do
            {:__block__, _, sort_args} -> sort_args
            sort_arg -> [sort_arg]
          end

        {
          :declare_fun,
          symbol(f),
          Enum.map(sort_args, &sort(&1)),
          sort(s)
        }
      end

    case commands do
      [command] -> command
      commands -> commands
    end
  end

  @spec numeral(Macro.t()) :: S.numeral_t()
  def numeral(n) when is_integer(n) do
    n
  end

  @spec string(Macro.t()) :: S.string_t()
  def string(s) when is_bitstring(s) do
    s
  end

  @spec symbol(Macro.t()) :: S.symbol_t()
  def symbol(s) when is_atom(s) do
    s
  end

  def symbol({:__aliases__, _, [s]}) when is_atom(s) do
    s
  end

  @spec sort(Macro.t()) :: S.sort_t()
  def sort(s) do
    {:sort, {:simple, symbol(s)}}
  end

  @spec term(Macro.t()) :: S.term_t()
  def term(s) when is_bitstring(s) do
    {:constant, {:string, string(s)}}
  end

  def term(n) when is_integer(n) do
    {:constant, {:numeral, numeral(n)}}
  end

  def term({:forall, _, [e, vs = [_ | _]]}) do
    {
      :forall,
      Enum.map(vs, &sorted_var(&1)),
      term(e)
    }
  end

  def term({{:., _, [f]}, _, es = [_ | _]}) do
    {
      :app,
      {:simple, symbol(f)},
      Enum.map(es, &term(&1))
    }
  end

  def term({f, _, es = [_ | _]}) when is_atom(f) do
    {
      :app,
      {:simple, infix(f)},
      Enum.map(es, &term(&1))
    }
  end

  def term(v) do
    {:identifier, {:simple, symbol(v)}}
  end

  @spec sorted_var(Macro.t()) :: S.sorted_var_t()
  def sorted_var({v, {:__aliases__, _, [s]}}) do
    {
      symbol(v),
      {:sort, {:simple, symbol(s)}}
    }
  end

  @spec commands(Macro.t()) :: [S.command_t()]
  def commands(ast) do
    List.flatten(commands_rec(ast))
  end

  @spec commands_rec(Macro.t()) :: [any()]
  defp commands_rec(ast) do
    case ast do
      {:__block__, _, ast} -> commands_rec(ast)
      [do: ast] -> commands_rec(ast)
      asts when is_list(asts) -> Enum.map(asts, &commands_rec(&1))
      ast -> List.wrap(command(ast))
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
