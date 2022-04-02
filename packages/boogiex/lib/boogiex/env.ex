defmodule Boogiex.Env do
  alias Boogiex.Theory
  alias Boogiex.Theory.Spec
  alias SmtLib.Syntax.From
  alias SmtLib.Connection, as: C

  @opaque t() :: %__MODULE__{connection: C.t()}
  defstruct [:connection]

  @spec new(C.t()) :: t()
  def new(connection) do
    env = %__MODULE__{connection: connection}

    SmtLib.API.run(
      connection(env),
      Theory.init() |> From.commands()
    )

    env
  end

  @spec clear(t()) :: :ok | {:error, term()}
  def clear(env) do
    env
    |> connection()
    |> C.close()
  end

  @spec connection(t()) :: SmtLib.Connection
  def connection(env) do
    env.connection
  end

  # TODO allow to customize?
  @spec error(t(), term()) :: :ok
  def error(_, e) do
    error_string =
      case e do
        string when is_bitstring(string) -> string
        other -> inspect(other)
      end

    IO.puts(error_string)
  end

  # TODO allow to customize?
  @spec function(t(), atom()) :: {atom(), [Spec.t()]} | nil
  def function(_, name) do
    Theory.function(name)
  end

  # TODO allow to customize?
  @spec literal(t(), term()) :: {atom(), atom(), atom()} | nil
  def literal(_, l) do
    Theory.literal(l)
  end
end
