defmodule Boogiex.Stm do
  alias Boogiex.Exp
  alias Boogiex.Msg
  alias Boogiex.Env
  alias Boogiex.Env.Smt
  alias Boogiex.Error.EnvError

  @type error_msg :: String.t() | (() -> String.t())

  @spec havoc(Env.t(), Exp.ast()) :: :ok | {:error, [term()]}
  def havoc(env, ast) do
    {term, errors} = Exp.exp(env, ast)

    Smt.run(
      env,
      fn -> Msg.havoc_context(ast) end,
      quote(do: declare_const([{unquote(term), Term}]))
    )

    to_result(env, errors)
  end

  @spec assume(Env.t(), Exp.ast(), error_msg()) :: :ok | {:error, [term()]}
  def assume(env, ast, error_msg) do
    {term, errors} = Exp.exp(env, ast)

    valid =
      Smt.check_valid(
        env,
        fn -> Msg.assume_context(ast) end,
        quote(do: :is_boolean.(unquote(term)))
      )

    Smt.run(
      env,
      fn -> Msg.assume_context(ast) end,
      quote(do: assert(:boolean_val.(unquote(term))))
    )

    to_result(
      env,
      if(valid, do: errors, else: [from_error_msg(error_msg) | errors])
    )
  end

  @spec assert(Env.t(), Exp.ast(), error_msg()) :: :ok | {:error, [term()]}
  def assert(env, ast, error_msg) do
    {term, errors} = Exp.exp(env, ast)

    valid_type =
      Smt.check_valid(
        env,
        fn -> Msg.assert_context(ast) end,
        quote(do: :is_boolean.(unquote(term)))
      )

    valid_value =
      Smt.check_valid(
        env,
        fn -> Msg.assert_context(ast) end,
        quote(do: :boolean_val.(unquote(term)))
      )

    Smt.run(
      env,
      fn -> Msg.assert_context(ast) end,
      quote(do: assert(:boolean_val.(unquote(term))))
    )

    to_result(
      env,
      if(valid_type && valid_value, do: errors, else: [from_error_msg(error_msg) | errors])
    )
  end

  @spec block(Env.t(), (() -> any())) :: any()
  def block(env, body) do
    Smt.run(
      env,
      &Msg.block_context/0,
      quote(do: push)
    )

    result = body.()

    Smt.run(
      env,
      &Msg.block_context/0,
      quote(do: pop)
    )

    result
  end

  @spec unfold(Env.t(), atom(), [Exp.ast()]) :: :ok | {:error, [term()]}
  def unfold(env, fun_name, args) do
    user_function =
      with nil <- Env.user_function(env, fun_name, length(args)) do
        raise EnvError,
          message: Msg.undefined_user_function(fun_name, args)
      end

    {succeed, errors} =
      with nil <- user_function.body do
        {Enum.empty?(user_function.specs), []}
      else
        body ->
          result =
            assume(
              env,
              quote(do: unquote(fun_name)(unquote_splicing(args)) === unquote(body.(args))),
              Msg.body_expansion_does_not_hold(fun_name, args)
            )

          case result do
            :ok -> {true, []}
            {:error, e} -> {false, e}
          end
      end

    {succeed, errors} =
      user_function.specs
      |> Enum.reduce({succeed, errors}, fn spec, {succeed, errors} ->
        with :ok <- block(env, fn -> assert(env, spec.pre.(args), "") end) do
          result1 =
            assume(env, spec.pre.(args), fn ->
              Msg.precondition_does_not_hold(fun_name, args)
            end)

          result2 =
            assume(env, spec.post.(args), fn ->
              Msg.postcondition_does_not_hold(fun_name, args)
            end)

          case {result1, result2} do
            {:ok, :ok} -> {true, errors}
            {{:error, e}, :ok} -> {succeed, [e | errors]}
            {:ok, {:error, e}} -> {succeed, [e | errors]}
            {{:error, e1}, {:error, e2}} -> {succeed, [e1, e2 | errors]}
          end
        else
          {:error, _} -> {succeed, errors}
        end
      end)

    to_result(
      env,
      List.flatten(
        if(succeed, do: errors, else: [Msg.no_precondition_holds(fun_name, args) | errors])
      )
    )
  end

  @spec to_result(Env.t(), [term()]) :: :ok | {:error, [term()]}
  defp to_result(env, errors) do
    case errors do
      [] ->
        :ok

      errors ->
        Env.error(env, errors)
        {:error, errors}
    end
  end

  @spec from_error_msg(error_msg()) :: String.t()
  defp from_error_msg(error_msg) when is_bitstring(error_msg) do
    error_msg
  end

  defp from_error_msg(error_msg) when is_function(error_msg) do
    error_msg.()
  end
end
