defmodule Boogiex.Env do
  alias Boogiex.Theory
  alias SmtLib.Connection
  alias Boogiex.Env.Config
  alias SmtLib.Syntax.From
  alias Boogiex.Theory.LitType
  alias Boogiex.Error.SmtError
  alias Boogiex.Theory.Function
  alias Boogiex.Env.UserFunction

  @opaque t() :: %__MODULE__{
            connection: Connection.t(),
            config: Config.t()
          }
  defstruct [:connection, :config]

  @spec new(Connection.t(), Config.params()) :: t()
  def new(connection, params) do
    config = Config.new(params)

    env = %__MODULE__{
      connection: connection,
      config: config
    }

    {_, result} =
      SmtLib.API.run(
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
      SmtLib.API.run(
        connection,
        config
        |> Config.user_functions()
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

    env
  end

  @spec clear(t()) :: :ok | {:error, term()}
  def clear(env) do
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
    env.config.on_error.(e)
  end

  @spec lit_type(t(), term()) :: LitType.t() | nil
  def lit_type(_, l) do
    Theory.lit_type(l)
  end

  @spec function(t(), atom(), non_neg_integer()) :: Function.t() | nil
  def function(env, name, arity) do
    with nil <- Theory.function(name, arity) do
      with nil <- Config.user_function(env.config, name, arity) do
        nil
      else
        f -> %Function{name: f.name}
      end
    end
  end

  @spec user_function(t(), atom(), non_neg_integer()) :: UserFunction.t() | nil
  def user_function(env, name, arity) do
    Config.user_function(env.config, name, arity)
  end
end
