defmodule Boogiex.Theory.Spec do
  alias SmtLib.Syntax.From

  @type t() :: %__MODULE__{
          pre: ([From.ast()] -> From.ast()),
          post: ([From.ast()] -> From.ast())
        }
  defstruct [:pre, :post]

  @spec native(atom(), atom(), atom(), atom()) :: t()
  def native(uni, nat, is_type, type_val) do
    native(uni, nat, is_type, type_val, is_type, type_val)
  end

  @spec native(atom(), atom(), atom(), atom(), atom(), atom()) :: t()
  def native(uni, nat, arg_is_type, arg_type_val, ret_is_type, ret_type_val) do
    %__MODULE__{
      pre: fn args ->
        empty_block =
          quote do
          end

        Enum.reduce(args, empty_block, fn
          arg, ^empty_block ->
            quote do
              unquote(arg_is_type).(unquote(arg))
            end

          arg, acc ->
            quote do
              unquote(acc) && unquote(arg_is_type).(unquote(arg))
            end
        end)
      end,
      post: fn args ->
        uni_app =
          quote do
            unquote(uni).(unquote_splicing(args))
          end

        nat_app =
          quote do
            unquote(nat)(
              unquote_splicing(
                for arg <- args do
                  quote do
                    unquote(arg_type_val).(unquote(arg))
                  end
                end
              )
            )
          end

        quote do
          unquote(ret_is_type).(unquote(uni_app)) &&
            unquote(ret_type_val).(unquote(uni_app)) == unquote(nat_app)
        end
      end
    }
  end
end
