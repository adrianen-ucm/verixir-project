import Boogiex

with_env do
  assert 4 - 2 === 6 - 4

  assert 2 === 1 + 1
  assert 2 === -(-2)
  assert false or true
  assert (false or 2) === 2
  assert (true and 4) === 4

  havoc x
  assert x === x
  assert not (x !== x)

  block do
    assume x === 2
    assert is_integer(x), "This should not fail"
  end

  assert is_integer(x), "This should fail"
end
