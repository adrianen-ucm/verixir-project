defmodule Boogiex.Env do
  alias Boogiex.BuiltIn
  alias SmtLib.Connection
  alias Boogiex.Msg
  alias Boogiex.Lang.SmtLib
  alias Boogiex.UserDefined
  alias Boogiex.BuiltIn.LitType
  alias Boogiex.Error.EnvError
  alias Boogiex.Env.TupleConstructor
  alias Boogiex.BuiltIn.Function, as: BuiltInFunction
  alias Boogiex.UserDefined.Function, as: UserFunction

  @opaque t() :: %__MODULE__{
            user_defined: UserDefined.t(),
            connection: Connection.t(),
            tuple_constructor: TupleConstructor.t()
          }
  defstruct [:user_defined, :connection, :tuple_constructor]

  @spec new(Connection.t()) :: t()
  @spec new(Connection.t(), UserDefined.params()) :: t()
  def new(connection, params \\ []) do
    user_defined = UserDefined.new(params)

    tuple_constructor =
      with {:ok, tuple_constructor} <- TupleConstructor.start() do
        tuple_constructor
      else
        {:error, e} ->
          raise EnvError,
            message: Msg.could_not_start_tuple_constructor(e)
      end

    env = %__MODULE__{
      user_defined: user_defined,
      connection: connection,
      tuple_constructor: tuple_constructor
    }

    SmtLib.run(
      env,
      &Msg.initialize_smt_context/0,
      BuiltIn.init()
    )

    SmtLib.run(
      env,
      &Msg.initialize_user_defined_context/0,
      user_defined
      |> UserDefined.functions()
      |> Enum.map(fn {name, arity} ->
        BuiltIn.declare_function(name, arity)
      end)
    )

    env
  end

  @spec clear(t()) :: :ok | {:error, term()}
  def clear(env) do
    TupleConstructor.stop(env.tuple_constructor)

    env
    |> connection()
    |> Connection.close()
  end

  @spec connection(t()) :: SmtLib.Connection
  def connection(env) do
    env.connection
  end

  @spec on_push(t()) :: :ok
  def on_push(env) do
    TupleConstructor.push(env.tuple_constructor)
  end

  @spec on_pop(t()) :: :ok
  def on_pop(env) do
    TupleConstructor.pop(env.tuple_constructor)
  end

  @spec lit_type(t(), term()) :: LitType.t() | nil
  def lit_type(_, l) do
    BuiltIn.lit_type(l)
  end

  @spec function(t(), atom(), non_neg_integer()) :: BuiltInFunction.t() | nil
  def function(env, name, arity) do
    with nil <- BuiltIn.function(name, arity) do
      with nil <- UserDefined.function(env.user_defined, name, arity) do
        nil
      else
        f -> %BuiltInFunction{name: f.name}
      end
    end
  end

  @spec user_function(t(), atom(), non_neg_integer()) :: UserFunction.t() | nil
  def user_function(env, name, arity) do
    UserDefined.function(env.user_defined, name, arity)
  end

  @spec tuple_constructor(t(), non_neg_integer()) :: atom()
  def tuple_constructor(env, n) do
    {fresh, name} =
      TupleConstructor.tuple_constructor(
        env.tuple_constructor,
        n
      )

    if fresh do
      SmtLib.run(
        env,
        fn -> Msg.tuple_constructor_context(name) end,
        BuiltIn.declare_function(name, n)
      )
    end

    name
  end
end
