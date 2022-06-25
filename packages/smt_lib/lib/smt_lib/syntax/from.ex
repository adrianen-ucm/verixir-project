defmodule SmtLib.Syntax.From do
  @moduledoc """
  Functions to translate a partial Elixir AST into the
  SMT-LIB syntax.
  """

  alias SmtLib.Syntax, as: S

  @type ast :: Macro.t()

  @spec command(ast()) :: Macro.t()
  def command({:check_sat, _, []}) do
    quote do
      :check_sat
    end
  end

  def command({:check_sat, _, a}) when is_atom(a) do
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
        [] -> 1
        a when is_atom(a) -> 1
      end

    quote do
      {:push, unquote(__MODULE__).numeral(unquote(n))}
    end
  end

  def command({:pop, _, args}) do
    n =
      case args do
        [n] -> n
        [] -> 1
        a when is_atom(a) -> 1
      end

    quote do
      {:pop, unquote(__MODULE__).numeral(unquote(n))}
    end
  end

  def command({:declare_const, _, [[_ | _] = vs]}) do
    commands =
      for {v, s} <- vs do
        quote do
          {
            :declare_const,
            unquote(__MODULE__).symbol(unquote(v)),
            unquote(sort(s))
          }
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
        [s] -> [s, 0]
      end

    quote do
      {
        :declare_sort,
        unquote(__MODULE__).symbol(unquote(s)),
        unquote(__MODULE__).numeral(unquote(n))
      }
    end
  end

  def command({:declare_fun, _, [[_ | _] = fs]}) do
    commands =
      for {f, {:"::", _, [ss, s]}} <- fs do
        quote do
          {
            :declare_fun,
            unquote(__MODULE__).symbol(unquote(f)),
            unquote(Enum.map(List.wrap(ss), &sort(&1))),
            unquote(sort(s))
          }
        end
      end

    case commands do
      [command] -> command
      commands -> commands
    end
  end

  def command({:define_fun, _, [[_ | _] = fs]}) do
    commands =
      for {f, {:<-, _, [{:"::", _, [ss, s]}, t]}} <- fs do
        quote do
          {
            :define_fun,
            unquote(__MODULE__).symbol(unquote(f)),
            unquote(Enum.map(List.wrap(ss), &sorted_var(&1))),
            unquote(sort(s)),
            unquote(term(t))
          }
        end
      end

    case commands do
      [command] -> command
      commands -> commands
    end
  end

  @spec numeral(non_neg_integer()) :: S.numeral_t()
  def numeral(n) when is_integer(n) do
    n
  end

  @spec string(String.t()) :: S.string_t()
  def string(s) when is_bitstring(s) do
    s
  end

  @spec symbol(atom()) :: S.symbol_t()
  def symbol(s) when is_atom(s) do
    s
  end

  def symbol({:__aliases__, _, [s]}) when is_atom(s) do
    s
  end

  @spec sort(ast()) :: Macro.t()
  def sort(s) do
    quote do
      {:sort, {:simple, unquote(__MODULE__).symbol(unquote(s))}}
    end
  end

  @spec term(ast()) :: Macro.t()
  def term(s) when is_bitstring(s) do
    quote do
      {:constant, {:string, unquote(__MODULE__).string(unquote(s))}}
    end
  end

  def term(n) when is_integer(n) do
    quote do
      {:constant, {:numeral, unquote(__MODULE__).numeral(unquote(n))}}
    end
  end

  def term(s) when is_atom(s) do
    quote do
      {:identifier, {:simple, unquote(__MODULE__).symbol(unquote(s))}}
    end
  end

  def term({:__aliases__, _, [s]}) when is_atom(s) do
    quote do
      {:identifier, {:simple, unquote(__MODULE__).symbol(unquote(s))}}
    end
  end

  def term({:__block__, _, [t]}) do
    term(t)
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

  def term({:exists, _, [e, vs = [_ | _]]}) do
    quote do
      {
        :exists,
        unquote(Enum.map(vs, &sorted_var(&1))),
        unquote(term(e))
      }
    end
  end

  def term({{:., _, [f]}, _, []}) do
    quote do
      {
        :identifier,
        {:simple, unquote(__MODULE__).symbol(unquote(f))}
      }
    end
  end

  def term({{:., _, [f]}, _, es = [_ | _]}) do
    quote do
      {
        :app,
        {:simple, unquote(__MODULE__).symbol(unquote(f))},
        unquote(Enum.map(es, &term(&1)))
      }
    end
  end

  def term({:unquote, _, [t]}) do
    quote do
      unquote(__MODULE__).term(unquote(t))
      |> Code.eval_quoted()
      |> elem(0)
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

  def term({name, _, m} = t) when is_atom(name) and is_atom(m) do
    quote do
      case unquote(t) do
        n when is_integer(n) -> {:constant, {:numeral, unquote(__MODULE__).numeral(n)}}
        s when is_bitstring(s) -> {:constant, {:string, unquote(__MODULE__).string(s)}}
        s when is_atom(s) -> {:identifier, {:simple, unquote(__MODULE__).symbol(s)}}
      end
    end
  end

  @spec sorted_var(ast()) :: Macro.t()
  def sorted_var({v, {:__aliases__, _, [s]}}) do
    quote do
      {
        unquote(__MODULE__).symbol(unquote(v)),
        {:sort, {:simple, unquote(__MODULE__).symbol(unquote(s))}}
      }
    end
  end

  def sorted_var({v, s}) do
    quote do
      {
        unquote(__MODULE__).symbol(unquote(v)),
        {:sort, {:simple, unquote(__MODULE__).symbol(unquote(s))}}
      }
    end
  end

  @spec commands(ast()) :: Macro.t()
  def commands(ast) do
    List.flatten(commands_rec(ast))
  end

  @spec commands_rec(ast()) :: deep_command_list
        when deep_command_list: [Macro.t() | deep_command_list]
  defp commands_rec(ast) do
    case ast do
      nil -> []
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
    <~>: :=,
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
