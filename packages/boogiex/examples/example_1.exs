import Boogiex

with_env do
  havoc x
  havoc result

  assume integer(x)

  assert integer(x)
  assert integer(x)
  assume integer(result)
  assume result == x + x

  assert integer(result)
  assert integer(2)
  assert integer(x)

  with :ok <- assert(result == 2 * x, "Not verified") do
    IO.puts("Verified")
  end
end
