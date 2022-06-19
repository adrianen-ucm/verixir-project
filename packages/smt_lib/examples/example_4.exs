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
  for {_, v} <- node_in_position do
    declare_const [{v, Bool}]
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
  for {{m, i}, v1} <- node_in_position, {{n, ^i}, v2} <- node_in_position, n !== m do
    assert !(v1 && v2)
  end

  # Non adjacent nodes cannot be in adjacent positions
  for {{m, i}, v1} <- node_in_position,
      j <- [i + 1],
      {{n, ^j}, v2} <- node_in_position,
      n !== m,
      {m, n} not in edges do
    assert v1 ~> !v2
  end

  check_sat
end
|> IO.inspect()
