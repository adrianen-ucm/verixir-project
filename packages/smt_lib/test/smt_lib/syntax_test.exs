defmodule SmtLib.SyntaxTest do
  import SmtLib.Syntax
  use ExUnit.Case, async: true
  doctest SmtLib.Syntax, import: true

  test "Constants of constant" do
    assert term_constants({
             :constant,
             {:numeral, 2}
           }) == MapSet.new([{:numeral, 2}])
  end

  test "Constants of variable" do
    assert term_constants({
             :identifier,
             {:simple, :x}
           }) == MapSet.new()
  end

  test "Constants of nullary app" do
    assert term_constants({
             :app,
             {:simple, :f},
             []
           }) == MapSet.new()
  end

  test "Constants of unary app" do
    assert term_constants({
             :app,
             {:simple, :f},
             [{:constant, {:numeral, 0}}]
           }) == MapSet.new([{:numeral, 0}])
  end

  test "Constants of app" do
    assert term_constants(
             {:app, {:simple, :f},
              [
                {:constant, {:numeral, 0}},
                {:identifier, {:simple, :x}},
                {:constant, {:numeral, 0}},
                {:constant, {:string, "example"}}
              ]}
           ) == MapSet.new([{:numeral, 0}, {:string, "example"}])
  end

  test "Constants of forall" do
    assert term_constants({
             :forall,
             [{:x, {:sort, {:simple, Bool}}}],
             {:constant, {:numeral, 0}}
           }) == MapSet.new([{:numeral, 0}])
  end

  test "Constants of nested terms" do
    assert term_constants({
             :forall,
             [{:x, {:sort, {:simple, Bool}}}],
             {:app, {:simple, :f},
              [
                {:constant, {:numeral, 0}},
                {:identifier, {:simple, :x}},
                {:constant, {:numeral, 0}},
                {:constant, {:string, "example"}}
              ]}
           }) == MapSet.new([{:numeral, 0}, {:string, "example"}])
  end
end
