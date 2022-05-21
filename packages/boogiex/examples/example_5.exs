import Boogiex

with_local_env(on_error: &IO.inspect/1) do
  assume true or true + true
  assume not (false and true + true)

  assert true or true + true
  assert not (false and true + true)

  havoc x
  assume is_integer(x) and x + 1 === 2
  assert x === 1

  assert false, "This should fail"
end
