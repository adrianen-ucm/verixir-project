defmodule SmtLib.Syntax.FromTest do
  import SmtLib.Syntax.From
  use ExUnit.Case, async: true
  doctest SmtLib.Syntax.From

  test "Command check-sat" do
    assert command(
             quote do
               check_sat
             end
           ) == :check_sat
  end

  test "Command assert" do
    assert command(
             quote do
               assert 2
             end
           ) == {:assert, {:constant, {:numeral, 2}}}
  end

  test "Command push" do
    assert command(
             quote do
               push
             end
           ) == {:push, 1}
  end

  test "Command push levels" do
    assert command(
             quote do
               push 2
             end
           ) == {:push, 2}
  end

  test "Command pop" do
    assert command(
             quote do
               pop
             end
           ) == {:pop, 1}
  end

  test "Command pop levels" do
    assert command(
             quote do
               pop 2
             end
           ) == {:pop, 2}
  end

  test "Command declare-const" do
    assert command(
             quote do
               declare_const x: Bool
             end
           ) == {:declare_const, :x, {:sort, {:simple, :Bool}}}
  end

  test "Command declare-const multiple" do
    assert command(
             quote do
               declare_const x: Bool,
                             n: Int
             end
           ) == [
             {:declare_const, :x, {:sort, {:simple, :Bool}}},
             {:declare_const, :n, {:sort, {:simple, :Int}}}
           ]
  end

  test "Command declare-sort" do
    assert command(
             quote do
               declare_sort Term
             end
           ) == {:declare_sort, :Term, 0}
  end

  test "Command declare-sort parameterized" do
    assert command(
             quote do
               declare_sort(Term, 1)
             end
           ) == {:declare_sort, :Term, 1}
  end

  test "Command declare-fun" do
    assert command(
             quote do
               declare_fun example: Bool :: Bool
             end
           ) == {:declare_fun, :example, [{:sort, {:simple, :Bool}}], {:sort, {:simple, :Bool}}}
  end

  test "Command declare-fun multiple" do
    assert command(
             quote do
               declare_fun example1: Bool :: Bool,
                           example2: [Bool, Int] :: Bool
             end
           ) == [
             {:declare_fun, :example1, [{:sort, {:simple, :Bool}}], {:sort, {:simple, :Bool}}},
             {:declare_fun, :example2, [{:sort, {:simple, :Bool}}, {:sort, {:simple, :Int}}],
              {:sort, {:simple, :Bool}}}
           ]
  end

  test "Command define-fun" do
    assert command(
             quote do
               define_fun example: [x: Bool] :: Bool <- :x != 3
             end
           ) == {
             :define_fun,
             :example,
             [{:x, {:sort, {:simple, :Bool}}}],
             {:sort, {:simple, :Bool}},
             {:app, {:simple, :distinct},
              [{:identifier, {:simple, :x}}, {:constant, {:numeral, 3}}]}
           }
  end

  test "Numeral" do
    assert numeral(
             quote do
               2
             end
           ) == 2
  end

  test "String" do
    assert string(
             quote do
               "example"
             end
           ) == "example"
  end

  test "Symbol" do
    assert symbol(
             quote do
               :example
             end
           ) == :example
  end

  test "Symbol from alias" do
    assert symbol(
             quote do
               Example
             end
           ) == :Example
  end

  test "Sort" do
    assert sort(
             quote do
               :bool
             end
           ) == {:sort, {:simple, :bool}}
  end

  test "Sort from alias" do
    assert sort(
             quote do
               Bool
             end
           ) == {:sort, {:simple, :Bool}}
  end
end
