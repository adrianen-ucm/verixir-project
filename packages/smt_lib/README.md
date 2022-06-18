# SmtLib

A Z3 binding for Elixir in terms of the SMT-LIB specification
and capabilities to also work with 
[other SMT-LIB interpreters](#other-smt-lib-interpreters).

This is currently in early development stage, so a small subset of 
SMT-LIB is supported and breaking changes can arise.

## Usage 

### Low level

- Create a new connection with `SmtLib.Connection.Z3.new/1` or 
a custom implementation of the 
[`SmtLib.Connection`](./lib/smt_lib/connection.ex) protocol.
- Send commands as specified in 
[`SmtLib.Syntax`](./lib/smt_lib/syntax.ex) through 
`SmtLib.Connection.send_command/2`.
- Get the responses back with `SmtLib.Connection.receive_response/1`.
- Close the connection with `SmtLib.Connection.close/1`.

### DSL

The `SmtLib` module offers a DSL which translates in compile time
to the low level machinery. It tries to be flexible enough to 
support different use cases.

This is an execution of executing commands one at a time:

```elixir
with_local_conn do
  declare_const x: Bool
  assert :x && !:x
  check_sat
end
|> IO.inspect()

# {:ok, :unsat}
```

This other one is the same but with error short-circuit:

```elixir
with_local_conn do
  with :ok <- declare_const(x: Bool),
       :ok <- assert(:x && !:x),
       {:ok, result} <- check_sat do
    result
  end
end
|> IO.inspect()

# :unsat
```

Identifiers and literals from commands can be parameterized:

```elixir
var_name = :x
var_sort = Bool

with_local_conn do
  declare_const [{var_name, var_sort}]
  assert var_name && !var_name
  check_sat
end
|> IO.inspect()

# {:ok, :unsat}
```

Also, by using the `SmtLib.API` module instead of the macros exposed in `SmtLib`, commands can be processed in batch and get the benefit of some parallelism when interacting with the solver.

## Other SMT-LIB interpreters

Although the implementation provided in this package uses Z3 through  
[Elixir ports](https://hexdocs.pm/elixir/Port.html), 
other interpreters can also be used by implementing the 
[`SmtLib.Connection`](./lib/smt_lib/connection.ex) protocol.
