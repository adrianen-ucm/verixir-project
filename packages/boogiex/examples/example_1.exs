import Boogiex

with_local_env(
  on_error: &IO.warn/1,
  user_functions: MapSet.new([{:dup, 1}])
) do
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

  havoc a
  havoc b
  havoc c

  assume is_integer(a) and is_integer(b) and is_integer(c)

  assume a === b
  assume b === c
  assert a === c

  havoc d
  assume is_integer(d)
  # alternative: store the body and do unfold(dup(d))
  define dup(d), as: d + d
  assert is_integer(dup(d))
  assert dup(d) === 2 * d
end
