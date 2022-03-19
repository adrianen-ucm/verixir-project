defmodule Boogiex.Theory do
  require SmtLib

  alias SmtLib.Syntax, as: S

  @spec init :: Macro.t()
  def init() do
    quote do
      declare_sort Term

      declare_fun is_integer: Term :: Bool,
                  integer_val: Term :: Int
    end
  end

  @spec for_term(S.term_t()) :: Macro.t()
  def for_term(term) do
    term
    |> SmtLib.Syntax.term_constants()
    |> Enum.map(&for_constant(&1))
  end

  defp for_constant({:numeral, n}) do
    quote do
      assert :is_integer.(unquote(n))
      assert :integer_val.(unquote(n)) == unquote(n)
    end
  end

  defp for_constant(_) do
    quote do
    end
  end
end
