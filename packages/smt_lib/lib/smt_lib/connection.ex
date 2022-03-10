defprotocol SmtLib.Connection do
  @moduledoc """
  Protocol for an SMT-LIB interpreter connection.
  """

  alias SmtLib.Syntax, as: S

  @spec send_command(t(), S.command_t()) :: :ok | {:error, term()}
  def send_command(connection, command)

  @spec receive_response(t()) :: {:ok, S.general_response_t()} | {:error, term()}
  def receive_response(connection)

  @spec close(t()) :: :ok | {:error, term()}
  def close(connection)
end
