defmodule Example do
  use Verixir

  @verifier requires is_integer(x)
  @verifier ensures dup(x) === 2 * x
  defv dup(x) when is_integer(x) do
    x + x
  end

  @verifier ensures not is_integer(dup(y))
  defv dup(y) do
    y
  end

  def main() do
    IO.puts("Using the defined function: dup(3) is #{dup(3)}")
  end
end

Example.main()
