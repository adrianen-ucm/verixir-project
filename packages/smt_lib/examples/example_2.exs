import SmtLib

run do
  # Common declarations
  declare_sort Term

  declare_fun is_integer: Term :: Bool,
              integer_val: Term :: Int,
              integer_lit: Int :: Term

  assert forall(
           :is_integer.(:integer_lit.(:x)) &&
             :integer_val.(:integer_lit.(:x)) == :x,
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
  assert !:is_integer.(:integer_lit.(2))
  check_sat
  pop
  assert :is_integer.(:integer_lit.(2))

  # assert is_integer(x)
  push
  assert !:is_integer.(:x)
  check_sat
  pop
  assert :is_integer.(:x)

  # assert result == 2 * x
  push
  assert :integer_val.(:result) != :integer_val.(:integer_lit.(2)) * :integer_val.(:x)
  check_sat
  pop
  assert :integer_val.(:result) == :integer_val.(:integer_lit.(2)) * :integer_val.(:x)
end
|> close()
|> IO.inspect()
