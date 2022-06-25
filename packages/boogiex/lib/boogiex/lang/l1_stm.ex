defmodule Boogiex.Lang.L1Stm do
  require Logger
  alias Boogiex.Msg
  alias Boogiex.Env
  alias Boogiex.Lang.L0Exp
  alias Boogiex.Lang.L1Exp
  alias Boogiex.UserDefined
  alias Boogiex.BuiltIn.TupleConstructor

  @type ast :: Macro.t()

  @spec eval(Env.t(), ast()) :: [term()]
  def eval(env, s) do
    Logger.debug(Macro.to_string(s), language: :l1)

    {e, tuple_constructor} =
      translate(
        s,
        Env.user_defined(env),
        Env.tuple_constructor(env)
      )

    Env.update_tuple_constructor(env, tuple_constructor)

    L0Exp.eval(
      Env.connection(env),
      Msg.evaluate_stm_context(s),
      e
    )
  end

  @spec translate(ast(), UserDefined.t(), TupleConstructor.t()) ::
          {L0Exp.ast(), TupleConstructor.t()}
  def translate({:havoc, _, [{var_name, _, _}]}, _, tuple_constructor) do
    {
      quote do
        context unquote(Msg.havoc_context(var_name)) do
          declare_const unquote(var_name)
        end
      end,
      tuple_constructor
    }
  end

  def translate({:assume, m, [f]}, user_defined, tuple_constructor) do
    translate(
      {:assume, m, [f, Msg.assume_failed(f)]},
      user_defined,
      tuple_constructor
    )
  end

  def translate({:assume, _, [f, error]}, user_defined, tuple_constructor) do
    {{f_t, f_sem}, tuple_constructor} =
      L1Exp.translate(
        f,
        user_defined,
        tuple_constructor
      )

    {
      quote do
        context unquote(Msg.assume_context(f)) do
          unquote_splicing([f_sem] |> Enum.reject(&is_nil/1))

          when_unsat add !:is_boolean.(unquote(f_t)) do
            add :boolean_val.(unquote(f_t))
          else
            fail unquote(error)
          end
        end
      end,
      tuple_constructor
    }
  end

  def translate({:assert, m, [f]}, user_defined, tuple_constructor) do
    translate(
      {:assert, m, [f, Msg.assert_failed(f)]},
      user_defined,
      tuple_constructor
    )
  end

  def translate({:assert, _, [f, error]}, user_defined, tuple_constructor) do
    {{f_t, f_sem}, tuple_constructor} =
      L1Exp.translate(
        f,
        user_defined,
        tuple_constructor
      )

    {
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
      end,
      tuple_constructor
    }
  end

  def translate({:block, _, [[do: s]]}, user_defined, tuple_constructor) do
    {t, tuple_constructor} = translate(s, user_defined, tuple_constructor)

    {
      quote do
        context unquote(Msg.block_context()) do
          local do
            unquote(t)
          end
        end
      end,
      tuple_constructor
    }
  end

  def translate({:__block__, _, es}, user_defined, tuple_constructor) do
    {es, tuple_constructor} =
      Enum.map_reduce(
        es,
        tuple_constructor,
        &translate(&1, user_defined, &2)
      )

    {
      quote do
        (unquote_splicing(es |> Enum.reject(&is_nil/1)))
      end,
      tuple_constructor
    }
  end
end
