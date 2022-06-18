import Boogiex

with_local_env do
  assert is_tuple({1, 2})

  assert tuple_size({}) === 0
  assert tuple_size({1}) === 1
  assert tuple_size({1, 2}) === 2
  assert tuple_size({1, 2, 3}) === 3

  assert elem({1, 2, 3}, 0) === 1
  assert elem({1, 2, 3}, 2) === 3

  assert {1, 2} === {1, 2}
  assert {1, 2} !== {1, 3}
  assert {1, 2} !== {1, 2, 3}

  havoc t
  assume is_tuple(t)
  assume tuple_size(t) === 2
  assume elem(t, 0) === 1
  assume elem(t, 1) === 2
  assert t === {1, 2}

  assert tuple_size({1, 2, 3, 4, 5, 6, 7, 8, 9, 10}) === 10

  havoc(x)
  havoc(y)

  assume {x, 2} === {y, 2}
  assert x === y

  havoc t1
  havoc t2
  assume is_tuple(t1)
  assume is_tuple(t2)
  assume tuple_size(t1) === 2
  assume tuple_size(t1) === tuple_size(t2)
  assume elem(t1, 0) === elem(t2, 0)
  assume elem(t1, 1) === elem(t2, 1)
  assert t1 === t2

  assert false, "This should fail"
end
