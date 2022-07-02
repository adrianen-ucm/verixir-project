defmodule Boogiex.Env do
  alias Boogiex.Msg
  alias Boogiex.BuiltIn
  alias SmtLib.Connection
  alias Boogiex.Lang.SmtLib
  alias Boogiex.UserDefined
  alias Boogiex.Error.EnvError
  alias Boogiex.BuiltIn.TupleConstructor

  @opaque t() :: %__MODULE__{
            user_defined: UserDefined.t(),
            connection: Connection.t(),
            tuple_constructor: pid()
          }
  defstruct [:user_defined, :connection, :tuple_constructor]

  @spec new(Connection.t()) :: t()
  @spec new(Connection.t(), UserDefined.params()) :: t()
  def new(connection, params \\ []) do
    user_defined = UserDefined.new(params)

    tuple_constructor =
      with {:ok, tuple_constructor} <- Agent.start_link(&TupleConstructor.new/0) do
        tuple_constructor
      else
        {:error, e} ->
          raise EnvError,
            message: Msg.could_not_start_tuple_constructor(e)
      end

    SmtLib.run(
      connection,
      Msg.initialize_smt_context(),
      BuiltIn.init()
    )

    SmtLib.run(
      connection,
      Msg.initialize_user_defined_context(),
      user_defined
      |> UserDefined.functions()
      |> Enum.map(fn {name, arity} ->
        BuiltIn.declare_function(name, arity)
      end)
    )

    %__MODULE__{
      user_defined: user_defined,
      connection: connection,
      tuple_constructor: tuple_constructor
    }
  end

  @spec clear(t()) :: :ok | {:error, term()}
  def clear(env) do
    Agent.stop(env.tuple_constructor)

    env
    |> connection()
    |> Connection.close()
  end

  @spec connection(t()) :: SmtLib.Connection
  def connection(env) do
    env.connection
  end

  @spec user_defined(t()) :: UserDefined.t()
  def user_defined(env) do
    env.user_defined
  end

  @spec tuple_constructor(t()) :: TupleConstructor.t()
  def tuple_constructor(env) do
    Agent.get(env.tuple_constructor, & &1)
  end

  @spec update_tuple_constructor(t(), TupleConstructor.t()) :: :ok
  def update_tuple_constructor(env, tuple_constructor) do
    diff =
      Agent.get_and_update(
        env.tuple_constructor,
        fn old_tuple_constructor ->
          {
            MapSet.difference(
              TupleConstructor.get_all(tuple_constructor),
              TupleConstructor.get_all(old_tuple_constructor)
            ),
            tuple_constructor
          }
        end
      )

    SmtLib.run(
      connection(env),
      Msg.tuple_constructor_context(diff),
      quote do
        (unquote_splicing(
           Enum.map(diff, fn {n, const} ->
             BuiltIn.declare_function(const, n)
           end)
         ))
      end
    )

    :ok
  end
end
