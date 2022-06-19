alias Boogiex.Lang.L2Exp
alias SmtLib.Connection.Z3
alias Boogiex.Env

env = Env.new(Z3.new())

L2Exp.verify(
  env,
  quote do
    [] = []
    {1, y} = {1, 2}
    # 3 + true

    ghost do
      assert y === 3, "y is not 3"
    end

    case true do
      # true when false -> 1
      # x -> x and x
      x when x -> x
    end

    case true do
      true when false -> 1
      true -> 3
    end

    ghost do
      assert y === 2, "y is not 2"
    end
  end
)

Env.clear(env)
