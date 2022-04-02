defmodule Boogiex.Error.EnvError do
  @type t :: %__MODULE__{message: String.t()}
  defexception [:message]
end
