import SmtLib

# One command at a time
with_local_conn do
  declare_const x: Bool
  assert :x && !:x
  check_sat
end
|> IO.inspect()

# One command at a time with error short-circuit
with_local_conn do
  with :ok <- declare_const(x: Bool),
       :ok <- assert(:x && !:x),
       {:ok, result} <- check_sat do
    result
  end
end
|> IO.inspect()

# Variable identifiers
with_local_conn do
  var_name = :x
  var_sort = Bool

  declare_const [{var_name, var_sort}]
  assert var_name && !var_name
  check_sat
end
|> IO.inspect()

with_local_conn do
  declare_const x: Int,
                y: Int

  assert !((:x + 3 <= :y + 3) ~> (:x <= :y))

  case check_sat do
    {:ok, :unsat} -> IO.puts("Verified!")
    _ -> IO.puts("Not verified")
  end
end
