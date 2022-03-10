defmodule SmtLib.Script do
  @moduledoc """
  An implementation of an `SmtLib` command binding in which each command
  is accumulated to be executed later in batch.
  """

  @behaviour SmtLib

  alias SmtLib.Syntax, as: S
  alias SmtLib.Connection, as: C
  alias SmtLib.Connection.Z3

  @opaque t :: %__MODULE__{
            commands: [S.command_t()],
            with_responses: [(S.general_response_t() -> any())]
          }
  defstruct commands: [], with_responses: []

  @doc """
  Creates an empty `SmtLib.Script`.
  """
  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end

  @doc """
  Executes the commands from an `SmtLib.Script` and returns an array
  with all their results. It uses a fresh connection from
  `SmtLib.Connection.Z3`.
  """
  @spec run(t()) :: [{:ok, S.general_response_t()} | {:error, term}]
  def run(script) do
    connection = Z3.new()
    result = run(script, connection)
    C.close(connection)
    result
  end

  @doc """
  Executes the commands from an `SmtLib.Script` and returns an array
  with all their results. It uses the provided `SmtLib.Connection`.
  """
  @spec run(t(), C.t()) :: [{:ok, S.general_response_t()} | {:error, term}]
  def run(script, connection) do
    send_commands_async(connection, script.commands)

    script.with_responses
    |> Enum.reverse()
    |> Enum.map(fn with_response ->
      case C.receive_response(connection) do
        {:ok, response} -> with_response.(response)
        err -> err
      end
    end)
  end

  @spec assert(t(), S.term_t()) :: t()
  def assert(script, term) do
    add(script, {:assert, term}, fn
      :success -> :ok
      other -> {:error, {:unexpected_command_response, other}}
    end)
  end

  @spec check_sat(t()) :: t()
  def check_sat(script) do
    add(script, :check_sat, fn
      {:specific_success_response, {:check_sat_response, response}} ->
        {:ok, response}

      other ->
        {:error, {:unexpected_command_response, other}}
    end)
  end

  @spec push(t(), S.numeral_t()) :: t()
  def push(script, levels \\ 1) do
    add(script, {:push, levels}, fn
      :success -> :ok
      other -> {:error, {:unexpected_command_response, other}}
    end)
  end

  @spec pop(t(), S.numeral_t()) :: t()
  def pop(script, levels \\ 1) do
    add(script, {:pop, levels}, fn
      :success -> :ok
      other -> {:error, {:unexpected_command_response, other}}
    end)
  end

  @spec declare_const(t(), S.symbol_t(), S.sort_t()) :: {t(), S.term_t()}
  def declare_const(script, name, sort) do
    {
      add(script, {:declare_const, name, sort}, fn
        :success -> :ok
        other -> {:error, {:unexpected_command_response, other}}
      end),
      {:identifier, {:simple, name}}
    }
  end

  @spec declare_sort(t(), S.symbol_t(), S.numeral_t()) :: {t(), S.sort_t()}
  def declare_sort(script, name, arity \\ 0) do
    {
      add(script, {:declare_sort, name, arity}, fn
        :success -> :ok
        other -> {:error, {:unexpected_command_response, other}}
      end),
      {:sort, {:simple, name}}
    }
  end

  @spec declare_fun(t(), S.symbol_t(), [S.sort_t(), ...], S.sort_t()) ::
          {t(), function_term}
        when function_term: (S.term_t() | [S.term_t(), ...] -> S.term_t())
  def declare_fun(script, name, arg_sorts, sort) do
    {
      add(script, {:declare_fun, name, arg_sorts, sort}, fn
        :success -> :ok
        other -> {:error, {:unexpected_command_response, other}}
      end),
      &{:app, {:simple, name}, &1}
    }
  end

  @spec add(t(), S.command_t(), (S.general_response_t() -> any())) :: t()
  defp add(script, command, with_response) do
    %__MODULE__{
      commands: [command | script.commands],
      with_responses: [with_response | script.with_responses]
    }
  end

  @spec send_commands_async(C.t(), [S.command_t()]) :: pid()
  defp send_commands_async(connection, commands) do
    spawn(fn ->
      commands
      |> Enum.reverse()
      |> Enum.each(fn command ->
        C.send_command(connection, command)
      end)
    end)
  end
end
