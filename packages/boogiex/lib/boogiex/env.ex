defmodule Boogiex.Env do
  alias Boogiex.Theory
  alias SmtLib.Syntax.From
  alias Boogiex.Theory.LitType
  alias Boogiex.Theory.Function
  alias Boogiex.Error.SmtError
  alias SmtLib.Connection, as: C

  @opaque t() :: %__MODULE__{connection: C.t()}
  defstruct [:connection]

  @spec new(C.t()) :: t()
  def new(connection) do
    env = %__MODULE__{connection: connection}

    {_, result} =
      SmtLib.API.run(
        connection(env),
        Theory.init() |> From.commands()
      )

    for r <- List.wrap(result) do
      with {:error, e} <- r do
        raise SmtError,
          error: e,
          context: "executing the Boogiex SMT-LIB initialization code"
      end
    end

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
  @spec function(t(), atom(), non_neg_integer()) :: Function.t() | nil
  def function(_, name, arity) do
    Theory.function(name, arity)
  end

  # TODO allow to customize?
  @spec lit_type(t(), term()) :: LitType.t() | nil
  def lit_type(_, l) do
    Theory.lit_type(l)
  end
end
