import Boogiex

with_env do
  havoc :x
  havoc :result

  assume :is_integer.(:x)

  assert :is_integer.(:x)
  assert :is_integer.(:x)
  assume :is_integer.(:result)
  assume :integer_val.(:result) == :integer_val.(:x) + :integer_val.(:x)

  assert :is_integer.(:result)
  assert :is_integer.(2)
  assert :is_integer.(:x)

  with :ok <-
         assert(:integer_val.(:result) == :integer_val.(2) * :integer_val.(:x), "Not verified") do
    IO.puts("Verified")
  end
end
