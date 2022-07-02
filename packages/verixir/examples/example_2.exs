defmodule Fib do
  use Verixir

  @verifier requires is_integer(n)
  @verifier ensures is_integer(fib(n))
  defvg fib(n) when n >= 0 do
    case n do
      0 -> 0
      1 -> 1
      n -> fib(n - 1) + fib(n - 2)
    end
  end

  @verifier requires is_integer(i) and
                       is_integer(n) and
                       is_integer(acc1) and
                       is_integer(acc2) and
                       i >= 0 and
                       n >= i and
                       acc1 === fib(i) and
                       acc2 === fib(i + 1)
  @verifier ensures is_integer(aux(n, i, acc1, acc2)) and
                      aux(n, i, acc1, acc2) === fib(n)
  defvp aux(n, i, acc1, acc2) do
    if n === i do
      acc1
    else
      unfold fib(i + 2)

      ghost do
        assert i + 2 - 2 === i
        assert i + 2 - 1 === i + 1
        assert i + 1 + 1 === i + 2
      end

      aux(n, i + 1, acc2, acc1 + acc2)
    end
  end

  @verifier requires is_integer(n)
  @verifier ensures is_integer(compute(n)) and compute(n) === fib(n)
  defv compute(n) when n >= 0 do
    unfold fib(0)
    unfold fib(1)

    ghost do
      assert 0 + 1 === 1
    end

    aux(n, 0, 0, 1)
  end
end

n = 100
IO.puts("fib(#{n}) is #{Fib.compute(n)}")
