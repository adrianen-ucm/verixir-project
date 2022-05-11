import Boogiex

with_local_env(on_error: &IO.inspect/1) do
  assert is_list([])
  assert length([]) === 0

  assert is_list([1, 2, 3])
  assert length([1, 2, 3]) === 3
  assert hd([1, 2, 3]) === 1
  assert tl([1, 2, 3]) === [2, 3]
end
