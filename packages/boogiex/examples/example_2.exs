import Boogiex

with_local_env do
  havoc x
  havoc result

  assume is_integer(x)

  assert is_integer(x)
  assert is_integer(x)
  assume is_integer(result)

  assume result === x + x

  assert is_integer(result)
  assert is_integer(2)
  assert is_integer(x)

  with :ok <- assert(result === 2 * x, "Not verified") do
    IO.puts("Verified")
  end
end
