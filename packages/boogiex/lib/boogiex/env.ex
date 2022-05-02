defmodule Boogiex.Env do
  alias Boogiex.Theory
  alias SmtLib.API
  alias SmtLib.Connection
  alias Boogiex.Env.UserEnv
  alias SmtLib.Syntax.From
  alias Boogiex.Theory.LitType
  alias Boogiex.Error.SmtError
  alias Boogiex.Error.EnvError
  alias Boogiex.Theory.Function
  alias Boogiex.Env.UserFunction
  alias Boogiex.Env.TupleConstructor

  @opaque t() :: %__MODULE__{
            user_env: UserEnv.t(),
            connection: Connection.t(),
            tuple_constructor: TupleConstructor.t()
          }
  defstruct [:user_env, :connection, :tuple_constructor]

  @spec new(Connection.t(), UserEnv.params()) :: t()
  def new(connection, params) do
    user_env = UserEnv.new(params)

    {_, result} =
      API.run(
        connection,
        Theory.init() |> From.commands()
      )

    for r <- List.wrap(result) do
      with {:error, e} <- r do
        raise SmtError,
          error: e,
          context: "executing the Boogiex SMT-LIB initialization code"
      end
    end

    {_, result} =
      API.run(
        connection,
        user_env
        |> UserEnv.user_functions()
        |> Enum.map(fn {name, arity} ->
          Theory.declare_function(name, arity)
        end)
        |> From.commands()
      )

    for r <- List.wrap(result) do
      with {:error, e} <- r do
        raise SmtError,
          error: e,
          context: "declaring the user defined functions"
      end
    end

    tuple_constructor =
      with {:ok, tuple_constructor} <- TupleConstructor.start() do
        tuple_constructor
      else
        {:error, e} ->
          raise EnvError,
            message: "Could not start the tuple constructor agent: #{inspect(e)}"
      end

    %__MODULE__{
      user_env: user_env,
      connection: connection,
      tuple_constructor: tuple_constructor
    }
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
      {_, result} =
        API.run(
          connection(env),
          Theory.declare_function(name, n)
          |> From.commands()
        )

      with {:error, e} <- result do
        raise SmtError,
          error: e,
          context: "declaring the tuple constructor #{name}"
      end
    end

    name
  end
end
