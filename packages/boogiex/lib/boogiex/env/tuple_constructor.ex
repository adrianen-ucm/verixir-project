defmodule Boogiex.Env.TupleConstructor do
  @type t :: pid()

  @spec start :: {:error, term()} | {:ok, t()}
  def start() do
    Agent.start_link(fn -> MapSet.new() end)
  end

  @spec stop(t()) :: :ok
  def stop(agent) do
    Agent.stop(agent)
  end

  @spec tuple_constructor(t(), non_neg_integer()) :: {boolean(), atom()}
  def tuple_constructor(agent, n) do
    Agent.get_and_update(agent, fn state ->
      name = "tuple_#{n}"

      if MapSet.member?(state, n) do
        {
          {false, String.to_existing_atom(name)},
          state
        }
      else
        {
          {true, String.to_atom(name)},
          MapSet.put(state, n)
        }
      end
    end)
  end
end
