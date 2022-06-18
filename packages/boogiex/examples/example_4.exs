import Boogiex

with_local_env do
  assert is_list([])
  assert is_list([1, 2, 3])
  assert hd([1, 2, 3]) === 1
  assert tl([1, 2, 3]) === [2, 3]
  assert [1 | [2 | [3 | []]]] === [1, 2, 3]
  assert [1, 2 | [3 | []]] === [1, 2, 3]
  assert tl([1 | 3]) === 3

  assert false, "This should fail"
end
