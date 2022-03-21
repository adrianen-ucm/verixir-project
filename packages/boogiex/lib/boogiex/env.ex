defmodule Boogiex.Env do
  alias Boogiex.Theory
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

  @spec error(t(), term()) :: nil
  def error(_, e) do
    IO.inspect(e)
  end
end
