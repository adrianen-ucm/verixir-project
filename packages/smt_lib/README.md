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

This is an execution of single commands with
their results gathered:

```elixir
run(declare_const x: Bool)
|> run(assert :x && !:x)
|> run(check_sat)
|> close()

# [:ok, :ok, {:ok, :unsat}]
```

This other one is the same but with error short-circuit:

```elixir
with {connection, :ok} <- run(declare_const x: Bool),
     {connection, :ok} <- run(connection, assert(:x && !:x)),
     {connection, {:ok, result}} <- run(connection, check_sat),
     :ok <- close(connection) do
  result
end

# :unsat
```

And this last one shows how a block of commands is grouped
into a sequence of commands to be executed in batch:

```elixir
run do
  declare_const x: Bool
  assert :x && !:x
  check_sat
end
|> close()

# [:ok, :ok, {:ok, :unsat}]
```

## Other SMT-LIB interpreters

Although the implementation provided in this package uses Z3 through  
[Elixir ports](https://hexdocs.pm/elixir/Port.html), 
other interpreters can also be used by implementing the 
[`SmtLib.Connection`](./lib/smt_lib/connection.ex) protocol.
