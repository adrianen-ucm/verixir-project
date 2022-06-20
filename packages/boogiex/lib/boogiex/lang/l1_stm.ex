defmodule Boogiex.Lang.L1Stm do
  require Logger
  alias Boogiex.Msg
  alias Boogiex.Env
  alias Boogiex.Lang.L0Exp
  alias Boogiex.Lang.L1Exp

  @type ast :: Macro.t()

  @spec eval(Env.t(), ast()) :: [term()]
  def eval(env, s) do
    Logger.debug(Macro.to_string(s), language: :l1)

    L0Exp.eval(
      env,
      fn -> Msg.evaluate_stm_context(s) end,
      translate(env, s)
    )
  end

  @spec translate(Env.t(), ast()) :: L0Exp.ast()
  def translate(_, {:havoc, _, [{var_name, _, _}]}) do
    quote do
      context unquote(fn -> Msg.havoc_context(var_name) end) do
        declare_const unquote(var_name)
      end
    end
  end

  def translate(env, {:assume, m, [f]}) do
    translate(env, {:assume, m, [f, Msg.assume_failed(f)]})
  end

  def translate(env, {:assume, _, [f, error]}) do
    {f_t, f_sem} = L1Exp.translate(env, f)

    quote do
      context unquote(Msg.assume_context(f)) do
        unquote_splicing([f_sem] |> Enum.reject(&is_nil/1))

        when_unsat add !:is_boolean.(unquote(f_t)) do
          add :boolean_val.(unquote(f_t))
        else
          fail unquote(error)
        end
      end
    end
  end

  def translate(env, {:assert, m, [f]}) do
    translate(env, {:assert, m, [f, Msg.assert_failed(f)]})
  end

  def translate(env, {:assert, _, [f, error]}) do
    {f_t, f_sem} = L1Exp.translate(env, f)

    quote do
      context unquote(Msg.assert_context(f)) do
        unquote_splicing([f_sem] |> Enum.reject(&is_nil/1))

        when_unsat add !:is_boolean.(unquote(f_t)) do
        else
          fail unquote(error)
        end

        when_unsat add !:boolean_val.(unquote(f_t)) do
          add :boolean_val.(unquote(f_t))
        else
          fail unquote(error)
        end
      end
    end
  end

  def translate(env, {:block, _, [[do: s]]}) do
    quote do
      context unquote(Msg.block_context()) do
        local do
          unquote(
            translate(
              env,
              s
            )
          )
        end
      end
    end
  end

  def translate(env, {:__block__, _, es}) do
    quote do
      (unquote_splicing(
         es
         |> Stream.map(&translate(env, &1))
         |> Enum.reject(&is_nil/1)
       ))
    end
  end
end
