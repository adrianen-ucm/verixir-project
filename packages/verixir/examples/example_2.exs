defmodule Example do
  use Verixir

  @verifier requires is_integer(n)
  @verifier ensures is_integer(fib_direct(n))
  defvp fib_direct(n) when n >= 0 do
    case n do
      0 -> 0
      1 -> 1
      n -> fib_direct(n - 1) + fib_direct(n - 2)
    end
  end

  @verifier requires is_integer(i) and
                       is_integer(n) and
                       is_integer(acc1) and
                       is_integer(acc2) and
                       i >= 0 and
                       n >= i and
                       acc1 === fib_direct(i) and
                       acc2 === fib_direct(i + 1)
  @verifier ensures is_integer(fib_aux(n, i, acc1, acc2)) and
                      fib_aux(n, i, acc1, acc2) === fib_direct(n)
  defvp fib_aux(n, i, acc1, acc2) do
    if n === i do
      acc1
    else
      unfold fib_direct(i + 2)

      ghost do
        assert i + 2 - 2 === i
        assert i + 2 - 1 === i + 1
        assert i + 1 + 1 === i + 2
      end

      fib_aux(n, i + 1, acc2, acc1 + acc2)
    end
  end

  @verifier requires is_integer(n)
  @verifier ensures is_integer(fib(n)) and fib(n) === fib_direct(n)
  defv fib(n) when n >= 0 do
    unfold fib_direct(0)
    unfold fib_direct(1)

    ghost do
      assert 0 + 1 === 1
    end

    fib_aux(n, 0, 0, 1)
  end
end

n = 100
IO.puts("fib(#{n}) is #{Example.fib(n)}")
