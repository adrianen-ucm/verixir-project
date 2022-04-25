defmodule Boogiex.Stm.Sugar do
  alias Boogiex.Stm
  alias Boogiex.Exp
  alias Boogiex.Env
  alias Boogiex.Error.EnvError

  @spec unfold(Env.t(), atom(), [Exp.ast()]) :: :ok | {:error, term()}
  def unfold(env, fun_name, args) do
    user_function =
      with nil <- Env.user_function(env, fun_name, length(args)) do
        f = Atom.to_string(fun_name)
        a = length(args)

        raise EnvError,
          message: "Undefined user function #{f}/#{a}"
      end

    with nil <- user_function.body do
    else
      body ->
        Stm.same(
          env,
          body.(args),
          quote(do: unquote(fun_name)(unquote_splicing(args)))
        )
    end

    error_message = "A precondition for #{fun_name} does not hold"

    Enum.reduce(user_function.specs, :ok, fn spec, first_result ->
      result = Stm.assert(env, spec.pre.(args), error_message)
      Stm.assume(env, spec.pre.(args))
      Stm.assume(env, spec.post.(args))

      with :ok <- first_result do
        result
      end
    end)
  end
end
