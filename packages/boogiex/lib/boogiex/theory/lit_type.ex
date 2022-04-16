defmodule Boogiex.Theory.LitType do
  @type t() :: %__MODULE__{
          is_type: atom(),
          type_val: atom(),
          type_lit: atom()
        }
  defstruct [:is_type, :type_val, :type_lit]
end
