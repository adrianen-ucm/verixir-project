import SmtLib.Session
alias SmtLib.Theory.Bool, as: B
alias SmtLib.Theory.Int, as: I

with_session(fn session ->
  # Common declarations
  with {:ok, term} <- declare_sort(session, "Term"),
       {:ok, is_integer} <- declare_fun(session, "is-integer", [term], B.sort()),
       {:ok, integer_val} <- declare_fun(session, "integer-val", [term], I.sort()),

       # This yields to problems. Maybe it is better to generate
       # the concrete asserts for the appearing literals.
       :ok <-
         assert(
           session,
           B.forall({"x", I.sort()}, fn x ->
             B.conj(
               is_integer.([x]),
               B.eq(
                 integer_val.([x]),
                 x
               )
             )
           end)
         ),

       # havoc x
       {:ok, x} <- declare_const(session, "x", term),

       # havoc result
       {:ok, result} <- declare_const(session, "result", term),

       # assume is_integer(x)
       :ok <- assert(session, is_integer.([x])),

       # assert is_integer(x)
       :ok <- push(session),
       :ok <- assert(session, B.neg(is_integer.([x]))),
       {:ok, :unsat} <- check_sat(session),
       :ok <- pop(session),
       :ok <- assert(session, is_integer.([x])),

       # assert is_integer(x)
       :ok <- push(session),
       :ok <- assert(session, B.neg(is_integer.([x]))),
       {:ok, :unsat} <- check_sat(session),
       :ok <- pop(session),
       :ok <- assert(session, is_integer.([x])),

       # assume is_integer(result)
       :ok <- assert(session, is_integer.([result])),

       # assume result == x + y
       :ok <-
         assert(
           session,
           B.eq(
             integer_val.([result]),
             I.add(integer_val.([x]), integer_val.([x]))
           )
         ),

       # assert is_integer(2)
       :ok <- push(session),
       :ok <- assert(session, B.neg(is_integer.([I.numeral(2)]))),
       {:ok, :unsat} <- check_sat(session),
       :ok <- pop(session),
       :ok <- assert(session, is_integer.([I.numeral(2)])),

       # assert is_integer(x)
       :ok <- push(session),
       :ok <- assert(session, B.neg(is_integer.([x]))),
       {:ok, :unsat} <- check_sat(session),
       :ok <- pop(session),
       :ok <- assert(session, is_integer.([x])),

       # assert result == 2 * x
       :ok <- push(session),
       :ok <-
         assert(
           session,
           B.neg(
             B.eq(
               integer_val.([result]),
               I.mul(I.numeral(2), integer_val.([x]))
             )
           )
         ),
       {:ok, :unsat} <- check_sat(session),
       :ok <- pop(session),
       :ok <-
         assert(
           session,
           B.eq(
             integer_val.([result]),
             I.mul(I.numeral(2), integer_val.([x]))
           )
         ) do
    IO.puts("All as expected")
  else
    err -> IO.inspect(err)
  end
end)
