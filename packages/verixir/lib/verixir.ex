defmodule Verixir do
  alias Boogiex.Env.UserFunction
  alias Boogiex.Env.UserSpec

  @verifier_key :verifier
  @verification_functions_key :verification_functions

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      @verifier_key unquote(@verifier_key)
      @verification_functions_key unquote(@verification_functions_key)

      Module.register_attribute(
        __MODULE__,
        @verification_functions_key,
        accumulate: true
      )

      Module.register_attribute(
        __MODULE__,
        @verifier_key,
        accumulate: true
      )
    end
  end

  @spec spec(Macro.t()) :: {:spec, Macro.t()}
  defmacro spec(args) do
    {:spec, Macro.escape(args)}
  end

  @spec defv(Macro.t()) :: Macro.t()
  @spec defv(Macro.t(), do: Macro.t()) :: Macro.t()
  defmacro defv({name, _, args}, keyword \\ []) do
    quote do
      Module.put_attribute(
        __MODULE__,
        @verification_functions_key,
        defv_no_macro(
          unquote(name),
          unquote(length(args)),
          unquote(replacer_for(args)),
          unquote(Macro.escape(Keyword.get(keyword, :do))),
          Module.delete_attribute(
            __MODULE__,
            @verifier_key
          )
        )
      )
    end
  end

  # TODO refactor
  def defv_no_macro(name, arity, replacer, body, attributes) do
    specs =
      for {:spec, spec} <- with(nil <- attributes, do: []) do
        user_spec = %UserSpec{}

        user_spec =
          case Keyword.get(spec, :requires) do
            nil -> user_spec
            requires -> %UserSpec{user_spec | pre: replacer.(requires)}
          end

        user_spec =
          case Keyword.get(spec, :ensures) do
            nil -> user_spec
            ensures -> %UserSpec{user_spec | post: replacer.(ensures)}
          end

        user_spec
      end

    body =
      case body do
        nil ->
          nil

        body ->
          replacer.(body)
      end

    %UserFunction{
      name: name,
      arity: arity,
      specs: specs,
      body: body
    }
  end

  # TODO study variable capturing problems
  defp replacer_for(vars) do
    var_names = Enum.map(vars, &elem(&1, 0))

    quote do
      fn exp ->
        fn unquote(vars) ->
          vals =
            Stream.zip(
              unquote(var_names),
              unquote(vars)
            )
            |> Enum.into(%{})

          Macro.prewalk(
            exp,
            fn
              {name, _, _} = var -> Map.get(vals, name, var)
              other -> other
            end
          )
        end
      end
    end
  end
end
