defmodule SmtLib.Session do
  @moduledoc """
  An implementation of an `SmtLib` command binding in which each command
  result is synchronously returned.
  """

  @behaviour SmtLib

  alias SmtLib.Syntax, as: S
  alias SmtLib.Connection, as: C
  alias SmtLib.Connection.Z3

  @opaque t :: %__MODULE__{connection: C.t()}
  defstruct [:connection]

  @doc """
  Creates an `SmtLib.Session` instance which holds an `SmtLib.Connection`.

  If no `SmtLib.Connection` is provided as argument, a fresh one from
  `SmtLib.Connection.Z3` is used.
  """
  @spec new(C.t()) :: t()
  def new(connection \\ Z3.new()) do
    %__MODULE__{connection: connection}
  end

  @doc """
  Closes an `SmtLib.Session` by closing its underlying `SmtLib.Connection`.
  """
  @spec close(t()) :: :ok | {:error, term()}
  def close(session) do
    C.close(session.connection)
  end

  @doc """
  Executes a function that requires an `SmtLib.Session` with a fresh
  and default one, which is closed once the function returns.
  """
  @spec with_session((t() -> result)) :: result
        when result: any()
  def with_session(action) do
    session = new()
    result = action.(session)
    close(session)
    result
  end

  @spec assert(t(), S.term_t()) :: :ok | {:error, term()}
  def assert(session, term) do
    sync_command(
      session,
      {:assert, term},
      fn
        :success -> :ok
        other -> {:error, {:unexpected_command_response, other}}
      end
    )
  end

  @spec check_sat(t()) :: {:ok, :sat | :unsat | :unknown} | {:error, term()}
  def check_sat(session) do
    sync_command(
      session,
      :check_sat,
      fn
        {:specific_success_response, {:check_sat_response, response}} -> {:ok, response}
        other -> {:error, {:unexpected_command_response, other}}
      end
    )
  end

  @spec push(t(), S.numeral_t()) :: :ok | {:error, term()}
  def push(session, levels \\ 1) do
    sync_command(
      session,
      {:push, levels},
      fn
        :success -> :ok
        other -> {:error, {:unexpected_command_response, other}}
      end
    )
  end

  @spec pop(t(), S.numeral_t()) :: :ok | {:error, term()}
  def pop(session, levels \\ 1) do
    sync_command(
      session,
      {:pop, levels},
      fn
        :success -> :ok
        other -> {:error, {:unexpected_command_response, other}}
      end
    )
  end

  @spec declare_const(t(), S.symbol_t(), S.sort_t()) ::
          {:ok, S.term_t()} | {:error, term()}
  def declare_const(session, name, sort) do
    sync_command(
      session,
      {:declare_const, name, sort},
      fn
        :success -> {:ok, {:identifier, {:simple, name}}}
        other -> {:error, {:unexpected_command_response, other}}
      end
    )
  end

  @spec declare_sort(t(), S.symbol_t(), S.numeral_t()) ::
          {:ok, S.sort_t()} | {:error, term()}
  def declare_sort(session, name, arity \\ 0) do
    sync_command(
      session,
      {:declare_sort, name, arity},
      fn
        :success -> {:ok, {:sort, {:simple, name}}}
        other -> {:error, {:unexpected_command_response, other}}
      end
    )
  end

  @spec declare_fun(t(), S.symbol_t(), [S.sort_t(), ...], S.sort_t()) ::
          {:ok, function_term} | {:error, term()}
        when function_term: (S.term_t() | [S.term_t(), ...] -> S.term_t())
  def declare_fun(session, name, arg_sorts, sort) do
    sync_command(
      session,
      {:declare_fun, name, arg_sorts, sort},
      fn
        :success -> {:ok, &{:app, {:simple, name}, &1}}
        other -> {:error, {:unexpected_command_response, other}}
      end
    )
  end

  @spec sync_command(t(), S.command_t(), (S.general_response_t() -> result)) ::
          result | {:error, term()}
        when result: any()
  defp sync_command(session, command, with_response) do
    with :ok <-
           C.send_command(
             session.connection,
             command
           ),
         {:ok, response} <-
           C.receive_response(session.connection) do
      with_response.(response)
    else
      err -> err
    end
  end
end
