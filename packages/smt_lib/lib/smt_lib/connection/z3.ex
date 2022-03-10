defmodule SmtLib.Connection.Z3 do
  @opaque t() :: %__MODULE__{port: port()}
  defstruct [:port]

  @type options :: keyword()

  @spec new() :: t()
  @spec new(options()) :: t()
  def new(options \\ []) do
    %__MODULE__{
      port:
        Port.open(
          {:spawn_executable, System.find_executable("z3")},
          [:binary, :hide, {:line, 1024}, args: args(options)]
        )
    }
  end

  @spec args(options()) :: [String.t()]
  defp args(options) do
    case Keyword.pop(options, :timeout) do
      {nil, []} ->
        ["-in", "-smt2"]

      {t, []} when is_integer(t) and t >= 0 ->
        ["-in", "-smt2", "-t:#{t}"]
    end
  end
end

defimpl SmtLib.Connection, for: SmtLib.Connection.Z3 do
  alias SmtLib.Syntax, as: S
  alias SmtLib.Connection, as: C
  alias SmtLib.String.From
  alias SmtLib.String.To

  @eoc "EOC"

  @spec send_command(C.t(), S.command_t()) :: :ok | {:error, term()}
  def send_command(connection, command) do
    try do
      if Port.command(
           connection.port,
           command_line(command),
           []
         ) do
        :ok
      else
        {:error, :port_command_failure}
      end
    rescue
      ArgumentError ->
        {:error, :port_command_failure}
    end
  end

  @spec receive_response(C.t()) :: {:ok, S.general_response_t()} | {:error, term()}
  def receive_response(connection) do
    Stream.cycle([nil])
    |> Enum.reduce_while(
      "",
      receive_step(
        connection.port,
        @eoc
      )
    )
    |> To.general_response()
  end

  @spec close(C.t()) :: :ok | {:error, term()}
  def close(connection) do
    try do
      Port.close(connection.port)
      :ok
    rescue
      ArgumentError ->
        {:error, :error_closing_port}
    end
  end

  @spec command_line(S.command_t()) :: String.t()
  defp command_line(command) do
    "#{From.command(command)}(echo \"#{@eoc}\")\n"
  end

  @spec receive_step(port(), String.t()) :: (nil, String.t() -> String.t())
  defp receive_step(port, eoc) do
    fn nil, acc ->
      receive do
        {^port, {:data, data}} ->
          case data do
            {_, ^eoc} -> {:halt, acc}
            {:eol, data} -> {:cont, acc <> data <> "\n"}
            {:noeol, data} -> {:cont, acc <> data}
          end
      end
    end
  end
end
