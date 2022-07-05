alias Boogiex.Lang.L2Code
alias SmtLib.Connection.Z3
alias Boogiex.Env

env = Env.new(Z3.new())

L2Code.verify(
  env,
  quote do
    ghost do
      havoc selector
    end

    result =
      if selector === 1 do
        1
      else
        false
      end

    result =
      if selector === 1 do
        result + 1
      else
        not result
      end
  end
)

Env.clear(env)
