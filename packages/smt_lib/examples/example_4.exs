import SmtLib

nodes = 0..3

edges = MapSet.new([{0, 1}, {1, 2}, {2, 3}])

# Variable identifiers
node_in_position =
  for n <- nodes, {_, i} <- Enum.with_index(nodes) do
    {{n, i}, String.to_atom("p_#{n}_#{i}")}
  end
  |> Map.new()

with_local_conn do
  # Declare the variables
  for n <- nodes, {_, i} <- Enum.with_index(nodes) do
    declare_const [{node_in_position[{n, i}], Bool}]
  end

  # Every node is at least in some position
  for n <- nodes do
    assert Enum.reduce(
             Enum.with_index(nodes),
             quote(do: false),
             fn {_, i}, acc ->
               quote do
                 unquote(acc) || unquote(node_in_position[{n, i}])
               end
             end
           )
  end

  # Nodes do not collide in their positions
  for m <- nodes, n <- nodes, n !== m, {_, i} <- Enum.with_index(nodes) do
    assert !(node_in_position[{m, i}] && node_in_position[{n, i}])
  end

  # Non adjacent nodes cannot be in adjacent positions
  for m <- nodes,
      n <- nodes,
      n !== m,
      not ({m, n} in edges or {n, m} in edges),
      {_, i} <- Enum.with_index(Enum.drop(nodes, 1)) do
    assert node_in_position[{m, i}] ~> !node_in_position[{n, i + 1}]
  end

  check_sat
end
|> IO.inspect()
