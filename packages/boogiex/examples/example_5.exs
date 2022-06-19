import Boogiex

with_local_env do
  assume true or true + true
  assume not (false and true + true)

  assert true or true + true
  assert not (false and true + true)

  havoc x
  assume is_integer(x) and x + 1 === 2
  assert x === 1

  havoc z
  assert not (true === z) or z

  assert false, "This should fail"
end
