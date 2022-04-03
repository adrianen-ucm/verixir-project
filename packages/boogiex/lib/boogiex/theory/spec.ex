defmodule Boogiex.Theory.Spec do
  alias SmtLib.Syntax.From

  @type t() :: %__MODULE__{
          pre: ([From.ast()] -> From.ast()),
          post: ([From.ast()] -> From.ast())
        }
  defstruct [:pre, :post]

  @spec unary_native(atom(), atom(), atom(), atom()) :: t()
  def unary_native(uni, nat, is_type, type_val) do
    unary_native(uni, nat, is_type, type_val, is_type, type_val)
  end

  @spec binary_native(atom(), atom(), atom(), atom()) :: t()
  def binary_native(uni, nat, is_type, type_val) do
    binary_native(uni, nat, is_type, type_val, is_type, type_val)
  end

  @spec unary_native(atom(), atom(), atom(), atom(), atom(), atom()) :: t()
  def unary_native(uni, nat, arg_is_type, arg_type_val, ret_is_type, ret_type_val) do
    %__MODULE__{
      pre: fn [x] ->
        quote do
          unquote(arg_is_type).(unquote(x))
        end
      end,
      post: fn [x] ->
        quote do
          unquote(ret_is_type).(unquote(uni).(unquote(x))) &&
            unquote(ret_type_val).(unquote(uni).(unquote(x))) ==
              unquote(nat)(unquote(arg_type_val).(unquote(x)))
        end
      end
    }
  end

  @spec binary_native(atom(), atom(), atom(), atom(), atom(), atom()) :: t()
  def binary_native(uni, nat, arg_is_type, arg_type_val, ret_is_type, ret_type_val) do
    %__MODULE__{
      pre: fn [x, y] ->
        quote do
          unquote(arg_is_type).(unquote(x)) && unquote(arg_is_type).(unquote(y))
        end
      end,
      post: fn [x, y] ->
        quote do
          unquote(ret_is_type).(unquote(uni).(unquote(x), unquote(y))) &&
            unquote(ret_type_val).(unquote(uni).(unquote(x), unquote(y))) ==
              unquote(nat)(unquote(arg_type_val).(unquote(x)), unquote(arg_type_val).(unquote(y)))
        end
      end
    }
  end
end
