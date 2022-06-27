defmodule Example do
  use Verixir

  @verifier requires is_integer(n)
  @verifier ensures is_integer(fib(n))
  defv fib(n) when n >= 0 do
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
  @verifier ensures fib2(n, i, acc1, acc2) === fib(n)
  defv fib2(n, i, acc1, acc2) do
    if n === i do
      acc1
    else
      unfold fib(i + 2)

      ghost do
        assert i + 2 - 2 === i
        assert i + 2 - 1 === i + 1
        assert i + 1 + 1 === i + 2
      end

      fib2(n, i + 1, acc2, acc1 + acc2)
    end
  end

  @verifier requires is_integer(n)
  @verifier ensures fib3(n) === fib(n)
  defv fib3(n) when n >= 0 do
    unfold fib(0)
    unfold fib(1)

    ghost do
      assert 0 + 1 === 1
    end

    fib2(n, 0, 0, 1)
  end
end
