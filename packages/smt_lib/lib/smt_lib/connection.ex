defprotocol SmtLib.Connection do
  @moduledoc """
  Low level protocol for an SMT-LIB interpreter connection.
  """

  alias SmtLib.Syntax, as: S

  @doc """
  Send and SMT-LIB command through a connection.
  """
  @spec send_command(t(), S.command_t()) :: :ok | {:error, term()}
  def send_command(connection, command)

  @doc """
  Receive a command response through a connection.
  """
  @spec receive_response(t()) :: {:ok, S.general_response_t()} | {:error, term()}
  def receive_response(connection)

  @doc """
  Close the connection.
  """
  @spec close(t()) :: :ok | {:error, term()}
  def close(connection)
end
