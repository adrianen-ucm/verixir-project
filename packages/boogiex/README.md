# Boogiex

An intermediate representation language for Elixir code 
verification inspired by Boogie.

```elixir
import Boogiex

with_env do
  assert 2 == 1 + 1
  assert false ~> true
  assert 3 > 2 && 1 <= 1

  havoc x
  assume is_integer(x)
  assert (x == 2) <~> (x == 3 - 1)
end
```
