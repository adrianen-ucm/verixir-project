import SmtLib.Script
alias SmtLib.Theory.Bool, as: B
alias SmtLib.Theory.Int, as: I

script = new()

# Common declarations
{script, term} = declare_sort(script, "Term")
{script, is_integer} = declare_fun(script, "is-integer", [term], B.sort())
{script, integer_val} = declare_fun(script, "integer-val", [term], I.sort())

# This yields to problems. Maybe it is better to generate
# the concrete asserts for the appearing literals.
script =
  assert(
    script,
    B.forall({"x", I.sort()}, fn x ->
      B.conj(
        is_integer.([x]),
        B.eq(
          integer_val.([x]),
          x
        )
      )
    end)
  )

# havoc x
{script, x} = declare_const(script, "x", term)

# havoc result
{script, result} = declare_const(script, "result", term)

script
# assume is_integer(x)
|> assert(is_integer.([x]))

# assert is_integer(x)
|> push()
|> assert(B.neg(is_integer.([x])))
|> check_sat()
|> pop()
|> assert(is_integer.([x]))
|> push()

# assert is_integer(x)
|> push()
|> assert(B.neg(is_integer.([x])))
|> check_sat()
|> pop()
|> assert(is_integer.([x]))

# assume is_integer(result)
|> assert(is_integer.([result]))

# assume result == x + y
|> assert(
  B.eq(
    integer_val.([result]),
    I.add(integer_val.([x]), integer_val.([x]))
  )
)

# assert is_integer(2)
|> push()
|> assert(B.neg(is_integer.([I.numeral(2)])))
|> check_sat()
|> pop()
|> assert(is_integer.([I.numeral(2)]))

# assert is_integer(x)
|> push()
|> assert(B.neg(is_integer.([x])))
|> check_sat()
|> pop()
|> assert(is_integer.([x]))

# assert result == 2 * x
|> push()
|> assert(
  B.neg(
    B.eq(
      integer_val.([result]),
      I.mul(I.numeral(2), integer_val.([x]))
    )
  )
)
|> check_sat()
|> pop()
|> assert(
  B.eq(
    integer_val.([result]),
    I.mul(I.numeral(2), integer_val.([x]))
  )
)

# Execute
|> run()
|> IO.inspect()
