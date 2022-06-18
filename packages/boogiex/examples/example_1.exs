import Boogiex

dup = %Boogiex.UserDefined.Function{
  name: :dup,
  arity: 1,
  body: fn [x] ->
    quote(do: unquote(x) + unquote(x))
  end
}

with_local_env(functions: [dup]) do
  assert 4 - 2 === 6 - 4

  assert 2 === 1 + 1
  assert 2 === -(-2)
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

  block do
    assume is_tuple({1, 2, 3})
  end

  block do
    assume is_tuple({1, 2, 3})
  end

  havoc a
  havoc b
  havoc c

  assume is_integer(a) and is_integer(b)
  assume is_integer(a) and is_integer(b) and is_integer(c)

  assume a === b
  assume b === c
  assert a === c

  havoc d
  assume is_integer(d)
  unfold dup(d)
  assert is_integer(dup(d))
  assert dup(d) === 2 * d

  assert false, "This should fail"
end
