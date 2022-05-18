defmodule Boogiex.Stm do
  alias Boogiex.Exp
  alias Boogiex.Env
  alias Boogiex.Env.Smt
  alias Boogiex.Error.EnvError

  @spec havoc(Env.t(), Exp.ast()) :: :ok | {:error, [term()]}
  def havoc(env, ast) do
    {term, errors} = Exp.exp(env, ast)

    Smt.run(
      env,
      fn -> havoc_context(ast) end,
      quote(do: declare_const([{unquote(term), Term}]))
    )

    to_result(env, errors)
  end

  @spec assume(Env.t(), Exp.ast(), term()) :: :ok | {:error, [term()]}
  def assume(env, ast, error_payload) do
    {term, errors} = Exp.exp(env, ast)

    valid =
      Smt.check_valid(
        env,
        fn -> assume_context(ast) end,
        quote(do: :is_boolean.(unquote(term)))
      )

    Smt.run(
      env,
      fn -> assume_context(ast) end,
      quote(do: assert(:boolean_val.(unquote(term))))
    )

    to_result(
      env,
      if(valid, do: errors, else: [error_payload | errors])
    )
  end

  @spec assert(Env.t(), Exp.ast(), term()) :: :ok | {:error, [term()]}
  def assert(env, ast, error_payload) do
    {term, errors} = Exp.exp(env, ast)

    valid_type =
      Smt.check_valid(
        env,
        fn -> assert_context(ast) end,
        quote(do: :is_boolean.(unquote(term)))
      )

    valid_value =
      Smt.check_valid(
        env,
        fn -> assert_context(ast) end,
        quote(do: :boolean_val.(unquote(term)))
      )

    Smt.run(
      env,
      fn -> assert_context(ast) end,
      quote(do: assert(:boolean_val.(unquote(term))))
    )

    to_result(
      env,
      if(valid_type && valid_value, do: errors, else: [error_payload | errors])
    )
  end

  @spec block(Env.t(), (() -> any())) :: any()
  def block(env, body) do
    Smt.run(
      env,
      "evaluating a block",
      quote(do: push)
    )

    result = body.()

    Smt.run(
      env,
      "evaluating a block",
      quote(do: pop)
    )

    result
  end

  @spec unfold(Env.t(), atom(), [Exp.ast()]) :: :ok | {:error, [term()]}
  def unfold(env, fun_name, args) do
    full_name = "#{Atom.to_string(fun_name)}/#{length(args)}"

    user_function =
      with nil <- Env.user_function(env, fun_name, length(args)) do
        raise EnvError,
          message: "Undefined user function #{full_name}"
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
              "#{full_name} body expansion does not hold"
            )

          case result do
            :ok -> {true, []}
            {:error, e} -> {false, e}
          end
      end

    {succeed, errors} =
      user_function.specs
      |> Enum.reduce({succeed, errors}, fn spec, {succeed, errors} ->
        with :ok <- block(env, fn -> assert(env, spec.pre.(args), nil) end) do
          result1 = assume(env, spec.pre.(args), "A #{full_name} precondition do not hold")
          result2 = assume(env, spec.post.(args), "A #{full_name} postcondition do not hold")

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
        if(succeed, do: errors, else: ["No precondition for #{full_name} holds" | errors])
      )
    )
  end

  @spec havoc_context(Exp.ast()) :: String.t()
  defp havoc_context(ast), do: "declaring the variable #{Macro.to_string(ast)}"

  @spec assume_context(Exp.ast()) :: String.t()
  defp assume_context(ast), do: "trying to assume #{Macro.to_string(ast)}"

  @spec assert_context(Exp.ast()) :: String.t()
  defp assert_context(ast), do: "trying to assert #{Macro.to_string(ast)}"

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
end
