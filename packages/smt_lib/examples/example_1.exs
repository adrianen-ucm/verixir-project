import SmtLib

# Command by command with result gathering
run(declare_const x: Bool)
|> run(assert :x && !:x)
|> run(check_sat)
|> close()
|> IO.inspect()

# Command by command with error short-circuit
with {connection, :ok} <- run(declare_const x: Bool),
     {connection, :ok} <- run(connection, assert(:x && !:x)),
     {connection, {:ok, result}} <- run(connection, check_sat),
     :ok <- close(connection) do
  IO.inspect(result)
else
  err -> IO.inspect(err)
end

# Batch
run do
  declare_const x: Bool
  assert :x && !:x
  check_sat
end
|> close()
|> IO.inspect()
