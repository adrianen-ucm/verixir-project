import SmtLib.Session
alias SmtLib.Theory.Bool, as: B

with_session(fn session ->
  with {:ok, x} <- declare_const(session, "x", B.sort()),
       :ok <- assert(session, B.conj(x, B.neg(x))),
       {:ok, result} <- check_sat(session) do
    IO.inspect(result)
  else
    err -> IO.inspect(err)
  end
end)
