defmodule Boogiex.Env do
  alias Boogiex.Theory
  alias SmtLib.Connection
  alias Boogiex.Msg
  alias Boogiex.Env.Smt
  alias Boogiex.Env.UserEnv
  alias Boogiex.Theory.LitType
  alias Boogiex.Error.EnvError
  alias Boogiex.Theory.Function
  alias Boogiex.Env.UserFunction
  alias Boogiex.Env.TupleConstructor

  @opaque t() :: %__MODULE__{
            assuming: boolean(),
            user_env: UserEnv.t(),
            connection: Connection.t(),
            tuple_constructor: TupleConstructor.t()
          }
  defstruct [:assuming, :user_env, :connection, :tuple_constructor]

  @spec new(Connection.t(), UserEnv.params()) :: t()
  def new(connection, params) do
    user_env = UserEnv.new(params)

    tuple_constructor =
      with {:ok, tuple_constructor} <- TupleConstructor.start() do
        tuple_constructor
      else
        {:error, e} ->
          raise EnvError,
            message: Msg.could_not_start_tuple_constructor(e)
      end

    env = %__MODULE__{
      assuming: false,
      user_env: user_env,
      connection: connection,
      tuple_constructor: tuple_constructor
    }

    Smt.run(
      env,
      &Msg.initialize_smt_context/0,
      Theory.init()
    )

    Smt.run(
      env,
      &Msg.initialize_user_defined_context/0,
      user_env
      |> UserEnv.user_functions()
      |> Enum.map(fn {name, arity} ->
        Theory.declare_function(name, arity)
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

  @spec set_assuming(Boogiex.Env.t()) :: Boogiex.Env.t()
  def set_assuming(env) do
    %__MODULE__{env | assuming: true}
  end

  @spec is_assuming(Boogiex.Env.t()) :: boolean()
  def is_assuming(env) do
    env.assuming
  end

  @spec connection(t()) :: SmtLib.Connection
  def connection(env) do
    env.connection
  end

  @spec error(t(), term()) :: :ok
  def error(env, e) do
    env.user_env.on_error.(e)
  end

  @spec lit_type(t(), term()) :: LitType.t() | nil
  def lit_type(_, l) do
    Theory.lit_type(l)
  end

  @spec function(t(), atom(), non_neg_integer()) :: Function.t() | nil
  def function(env, name, arity) do
    with nil <- Theory.function(name, arity) do
      with nil <- UserEnv.user_function(env.user_env, name, arity) do
        nil
      else
        f -> %Function{name: f.name}
      end
    end
  end

  @spec user_function(t(), atom(), non_neg_integer()) :: UserFunction.t() | nil
  def user_function(env, name, arity) do
    UserEnv.user_function(env.user_env, name, arity)
  end

  @spec tuple_constructor(t(), non_neg_integer()) :: atom()
  def tuple_constructor(env, n) do
    {fresh, name} =
      TupleConstructor.tuple_constructor(
        env.tuple_constructor,
        n
      )

    if fresh do
      Smt.run(
        env,
        fn -> Msg.tuple_constructor_context(name) end,
        quote do
          unquote(Theory.declare_function(name, n))
          unquote(Theory.declare_tuple_term_size(n))
        end
      )
    end

    name
  end
end
