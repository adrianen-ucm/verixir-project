defmodule Boogiex.Env.TupleConstructor do
  @type t :: pid()

  @typep state :: nonempty_list(MapSet.t(non_neg_integer()))

  @spec start :: {:error, term()} | {:ok, t()}
  def start() do
    Agent.start_link(fn -> [MapSet.new()] end)
  end

  @spec stop(t()) :: :ok
  def stop(agent) do
    Agent.stop(agent)
  end

  @spec tuple_constructor(t(), non_neg_integer()) :: {boolean(), atom()}
  def tuple_constructor(agent, n) do
    Agent.get_and_update(agent, fn state ->
      name = "tuple_#{n}"

      if state_member(state, n) do
        {
          {false, String.to_existing_atom(name)},
          state
        }
      else
        {
          {true, String.to_atom(name)},
          top_put(state, n)
        }
      end
    end)
  end

  @spec push(t()) :: :ok
  def push(agent) do
    Agent.update(agent, &push_state/1)
  end

  @spec pop(t()) :: :ok
  def pop(agent) do
    Agent.update(agent, &pop_state/1)
  end

  @spec state_member(state(), non_neg_integer()) :: boolean()
  defp state_member([set], n) do
    MapSet.member?(set, n)
  end

  defp state_member([set | state], n) do
    MapSet.member?(set, n) or state_member(state, n)
  end

  @spec top_put(state(), non_neg_integer()) :: state()
  defp top_put([set | state], n) do
    [MapSet.put(set, n) | state]
  end

  @spec push_state(state()) :: state()
  defp push_state(state) do
    [MapSet.new() | state]
  end

  @spec pop_state(state()) :: state()
  defp pop_state([_ | [_ | _] = state]) do
    state
  end
end
