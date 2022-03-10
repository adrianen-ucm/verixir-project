import SmtLib.Script
alias SmtLib.Theory.Bool, as: B

script = new()
{script, x} = declare_const(script, "x", B.sort())

script
|> assert(B.conj(x, B.neg(x)))
|> check_sat()
|> run()
|> IO.inspect()
