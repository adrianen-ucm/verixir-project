import Boogiex

with_local_env(on_error: &IO.inspect/1) do
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
end
