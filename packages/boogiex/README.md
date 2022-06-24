# Boogiex

An intermediate representation language for Elixir code verification inspired by Boogie.

```elixir
import Boogiex

with_local_env do
  assert 2 === 1 + 1
  assert false or true
  assert (false or 2) === 2
  assert (true and 4) === 4
  assert 3 > 2 and 1 <= 1

  havoc x
  assert x === x
  assert not (x !== x)

  block do
    assume x === 2
    assert is_integer(x), "This should not fail"
  end

  assert is_integer(x), "This should fail"

  havoc a
  havoc b
  havoc c

  assume is_integer(a) and is_integer(b) and is_integer(c)

  assume a === b
  assume b === c
  assert a === c
end
```

This is currently in early development stage and breaking changes can arise.
