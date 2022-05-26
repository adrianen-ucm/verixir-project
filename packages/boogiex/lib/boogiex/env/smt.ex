defmodule Boogiex.Env.Smt do
  alias Boogiex.Env
  alias SmtLib.API
  alias SmtLib.Syntax.From
  alias Boogiex.Error.SmtError

  @type context :: String.t() | (() -> String.t())

  @spec run(Boogiex.Env.t(), context(), From.ast()) :: nil
  def run(env, context, commands) do
    API.run(
      Env.connection(env),
      From.commands(commands)
    )
    |> elem(1)
    |> List.wrap()
    |> Enum.reduce(nil, fn
      {:error, e}, _ -> raise SmtError, error: e, context: from_context(context)
      _, acc -> acc
    end)
  end

  @spec check_valid(Boogiex.Env.t(), context(), From.ast()) :: boolean()
  def check_valid(env, context, ast) do
    {_, results} =
      API.run(
        Env.connection(env),
        From.commands(
          quote do
            push

            unquote(
              Env.assumptions(env)
              |> Enum.map(fn a ->
                quote(do: assert(unquote(a)))
              end)
            )

            assert !unquote(ast)
            check_sat
            pop
          end
        )
      )

    [push_result | results] = results

    {assumption_results, results} =
      Enum.split(
        results,
        length(Env.assumptions(env))
      )

    [assert_result, sat_result, pop_result] = results

    for result <- assumption_results do
      with {:error, e} <- result do
        raise SmtError, error: e, context: from_context(context)
      end
    end

    :unsat ==
      with :ok <- push_result,
           :ok <- assert_result,
           {:ok, result} <- sat_result,
           :ok <- pop_result do
        result
      else
        {:error, e} -> raise SmtError, error: e, context: from_context(context)
      end
  end

  @spec from_context(context()) :: String.t()
  defp from_context(context) when is_bitstring(context) do
    context
  end

  defp from_context(context) when is_function(context) do
    context.()
  end
end
