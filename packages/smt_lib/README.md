# SmtLib

A Z3 binding for Elixir in terms of the SMT-LIB specification
and capabilities to also work with 
[other SMT-LIB interpreters](#other-smt-lib-interpreters).

This is currently in early development stage, so a small subset of 
SMT-LIB is supported and beaking changes can arise.

## Usage 

### Low level

- Create a new connection with `SmtLib.Connection.Z3.new/1` or 
a custom implementation of `SmtLib.Connection`.
- Send commands as specified in `SmtLib.Syntax` through 
`SmtLib.Connection.send_command/2`.
- Get the responses back with `SmtLib.Connection.receive_response/1`.
- Close the connection with `SmtLib.Connection.close/1`.

### Session

The `SmtLib.Session` module offers an abstraction built on top 
of the low level machinery which allows to execute commands and 
get their responses in a synchronous way.

```elixir
import SmtLib.Session
alias SmtLib.Theory.Bool, as: B

with_session(fn session ->
  with {:ok, x} <- declare_const(session, "x", B.sort()),
       :ok <- assert(session, B.conj(x, B.neg(x))),
       {:ok, result} <- check_sat(session) do
    result
  else
    err -> err
  end
end)

# :unsat
```

### Script

The `SmtLib.Script` module offers an abstraction, built also on 
top of the low level machinery, which allows to group a sequence 
of commands, run them and get all their responses back at once.

```elixir
import SmtLib.Script
alias SmtLib.Theory.Bool, as: B

script = new()
{script, x} = declare_const(script, "x", B.sort())

script
|> assert(B.conj(x, B.neg(x)))
|> check_sat()
|> run()

# [:ok, :ok, {:ok, :unsat}]
```

## Other SMT-LIB interpreters

Although the implementation provided in this package uses Z3 through  
[Elixir ports](https://hexdocs.pm/elixir/Port.html), 
other interpreters can also be used by implementing the 
[`SmtLib.Connection`](./lib/smt_lib/connection.ex) protocol.
