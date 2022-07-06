defmodule Verixir do
  alias Boogiex.Env
  alias Boogiex.Lang.L2Code
  alias Boogiex.UserDefined.Function
  alias Boogiex.BuiltIn.TupleConstructor
  alias SmtLib.Connection.Z3, as: Connection

  @typep def_kind :: :ghost | :private | :public

  @spec __using__([]) :: Macro.t()
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      @verifier_key :verifier
      @verification_functions_key :verification_functions

      Module.register_attribute(
        __MODULE__,
        @verification_functions_key,
        accumulate: false
      )

      Module.register_attribute(
        __MODULE__,
        @verifier_key,
        accumulate: true
      )

      @before_compile unquote(__MODULE__)
    end
  end

  @spec requires(Macro.t()) :: {:requires, Macro.t()}
  defmacro requires(args) do
    {:requires, Macro.escape(args)}
  end

  @spec ensures(Macro.t()) :: {:ensures, Macro.t()}
  defmacro ensures(args) do
    {:ensures, Macro.escape(args)}
  end

  @spec defv(Macro.t(), do: Macro.t()) :: Macro.t()
  defmacro defv(ast, do: body) do
    expand_function(ast, body, :public)
  end

  @spec defvp(Macro.t(), do: Macro.t()) :: Macro.t()
  defmacro defvp(ast, do: body) do
    expand_function(ast, body, :private)
  end

  @spec defvg(Macro.t(), do: Macro.t()) :: Macro.t()
  defmacro defvg(ast, do: body) do
    expand_function(ast, body, :ghost)
  end

  @spec expand_function(Macro.t(), Macro.t(), def_kind()) :: Macro.t()
  defp expand_function(ast, body, kind) do
    {name, args, guard} =
      case ast do
        {:when, _, [{name, _, args}, guard]} -> {name, args, guard}
        {name, _, args} -> {name, args, true}
      end

    quote do
      verifier =
        with nil <-
               Module.delete_attribute(
                 __MODULE__,
                 @verifier_key
               ) do
          []
        end

      verification_functions =
        with nil <-
               Module.delete_attribute(
                 __MODULE__,
                 @verification_functions_key
               ) do
          %{}
        end

      {pre, verifier} = Keyword.pop(verifier, :requires, true)
      {post, verifier} = Keyword.pop(verifier, :ensures, true)
      guard = unquote(Macro.escape(guard))

      function_def = %Function{
        body: unquote(Macro.escape(body)),
        args: unquote(Macro.escape(args)),
        pre: quote(do: unquote(pre) and unquote(guard)),
        post: post
      }

      verification_functions =
        Map.update(
          verification_functions,
          {unquote(name), unquote(length(args))},
          [function_def],
          fn defs -> [function_def | defs] end
        )

      Module.put_attribute(
        __MODULE__,
        @verification_functions_key,
        verification_functions
      )

      unquote(
        case kind do
          :public ->
            quote do
              def unquote(name)(unquote_splicing(args)) when unquote(guard) do
                unquote(L2Code.remove_ghost(body))
              end
            end

          :private ->
            quote do
              defp unquote(name)(unquote_splicing(args)) when unquote(guard) do
                unquote(L2Code.remove_ghost(body))
              end
            end

          :ghost ->
            nil
        end
      )
    end
  end

  @spec __before_compile__(Macro.Env.t()) :: Macro.t()
  defmacro __before_compile__(_) do
    quote do
      verification_functions =
        with nil <-
               Module.delete_attribute(
                 __MODULE__,
                 @verification_functions_key
               ) do
          %{}
        end
        |> Map.new(fn {k, defs} ->
          {k, Enum.reverse(defs)}
        end)

      env =
        Env.new(
          Connection.new(),
          functions: verification_functions
        )

      Env.update_tuple_constructor(
        env,
        Enum.reduce(0..10, Env.tuple_constructor(env), fn n, t ->
          TupleConstructor.get(t, n)
          |> elem(1)
        end)
      )

      for {{name, arity}, defs} <- verification_functions do
        IO.puts("Verifying #{name}/#{arity}")

        fresh_vars = Macro.generate_arguments(arity, nil)

        L2Code.verify(
          env,
          quote do
            ghost do
              (unquote_splicing(
                 for v <- fresh_vars do
                   quote do
                     havoc(unquote(v))
                   end
                 end
               ))
            end

            unquote(
              {:case, [],
               [
                 quote(do: {unquote_splicing(fresh_vars)}),
                 [
                   do:
                     List.flatten([
                       for d <- defs do
                         quote do
                           {unquote_splicing(d.args)}
                           when unquote(d.pre) ->
                             res = unquote(d.body)

                             ghost do
                               assume res === unquote(name)(unquote_splicing(fresh_vars))
                               assert unquote(d.post)
                             end
                         end
                       end,
                       quote do
                         {unquote_splicing(fresh_vars)} ->
                           ghost do
                             assume false
                           end
                       end
                     ])
                 ]
               ]}
            )
          end
        )
      end

      Env.clear(env)
    end
  end
end
