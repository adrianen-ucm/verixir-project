import SmtLib

run do
  # Common declarations
  declare_sort Term

  declare_fun is_integer: Term :: Bool,
              integer_val: Term :: Int

  assert forall(
           :is_integer.(:x) && :integer_val.(:x) == :x,
           x: Int
         )
end
|> run do
  # havoc x, havoc result
  declare_const x: Term,
                result: Term

  # assume is_integer(x)
  assert :is_integer.(:x)

  # assert is_integer(x)
  push
  assert !:is_integer.(:x)
  check_sat
  pop
  assert :is_integer.(:x)

  # assert is_integer(x)
  push
  assert !:is_integer.(:x)
  check_sat
  pop
  assert :is_integer.(:x)

  # assume is_integer(result)
  assert :is_integer.(:result)

  # assume result == x + x
  assert :integer_val.(:result) == :integer_val.(:x) + :integer_val.(:x)

  # assert is_integer(2)
  push
  assert !:is_integer.(2)
  check_sat
  pop
  assert :is_integer.(2)

  # assert is_integer(x)
  push
  assert !:is_integer.(:x)
  check_sat
  pop
  assert :is_integer.(:x)

  # assert result == 2 * x
  push
  assert :integer_val.(:result) != 2 * :integer_val.(:x)
  check_sat
  pop
  assert :integer_val.(:result) == 2 * :integer_val.(:x)
end
|> close()
|> IO.inspect()
