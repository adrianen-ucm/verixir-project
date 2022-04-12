import Boogiex

with_env do
  assert 2 === 1 + 1
  assert false or true
  assert 3 > 2 and 1 <= 1
end
