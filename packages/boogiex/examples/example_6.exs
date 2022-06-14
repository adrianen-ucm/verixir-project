alias Boogiex.Lang.L2Exp
alias SmtLib.Connection.Z3
alias Boogiex.Env

env = Env.new(Z3.new(), on_error: &IO.inspect/1)

L2Exp.validate(
  env,
  quote do
    [] = []
    {1, y} = {1, 2}
    # 3 + true

    ghost do
      assert y === 3, "This does not hold"
    end

    case true do
      true when false -> 1
      true -> 3
    end
  end
)

Env.clear(env)
