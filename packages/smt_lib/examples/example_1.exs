import SmtLib

# One command at a time with result gathering
run(declare_const x: Bool)
|> run(assert :x && !:x)
|> run(check_sat)
|> close()
|> IO.inspect()

# One command at a time with error short-circuit
with {connection, :ok} <- run(declare_const x: Bool),
     {connection, :ok} <- run(connection, assert(:x && !:x)),
     {connection, {:ok, result}} <- run(connection, check_sat),
     :ok <- close(connection) do
  result
end
|> IO.inspect()

# Batch
run do
  declare_const x: Bool
  assert :x && !:x
  check_sat
end
|> close()
|> IO.inspect()
