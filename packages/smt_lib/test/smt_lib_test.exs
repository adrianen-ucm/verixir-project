defmodule SmtLibTest do
  import SmtLib
  use ExUnit.Case, async: true
  doctest SmtLib, import: true

  test "Run a single command" do
    result =
      run(declare_sort Nat)
      |> close()

    assert :ok = result
  end

  test "Run an empty block" do
    result =
      run do
      end
      |> close()

    assert [] = result
  end

  test "Run a singleton block" do
    result =
      run do
        declare_const x: Bool
      end
      |> close()

    assert :ok = result
  end

  test "Run a multiline block" do
    result =
      run do
        declare_sort Nat

        declare_const m: Nat,
                      n: Nat
      end
      |> close()

    assert [:ok, :ok, :ok] = result
  end

  test "Nested blocks are flattened" do
    result =
      run do
        (
          declare_sort Nat

          declare_const m: Nat,
                        n: Nat
        )

        assert :m == :n

        (
          assert :m != :n

          (
            check_sat
            push
            pop
          )
        )
      end
      |> close()

    assert [:ok, :ok, :ok, :ok, :ok, {:ok, :unsat}, :ok, :ok] = result
  end

  test "Chained results are accumulated starting with single command" do
    result =
      run(declare_const x: Bool)
      |> run do
        declare_fun example1: [Bool, Bool] :: Bool,
                    example2: Bool :: Bool
      end
      |> run do
        assert :example1.(:x, :x) && :example2.(:x)
      end
      |> close()

    assert [:ok, :ok, :ok, :ok] = result
  end

  test "Chained results are accumulated starting with empty block" do
    result =
      run do
      end
      |> run do
        declare_const x: Bool
      end
      |> run do
        assert forall(
                 :x == :y,
                 x: Bool,
                 y: Bool
               )
      end
      |> close()

    assert [:ok, :ok] = result
  end

  test "Close just the connection" do
    {connection, []} =
      run do
      end

    assert :ok = close(connection)
  end

  test "A command results in error" do
    result =
      run(assert :x)
      |> close()

    assert {:error, _} = result
  end

  test "Assert some commands result in error" do
    result =
      run do
        assert :x
        declare_const x: Bool
        assert :y
      end
      |> close()

    assert [{:error, _}, :ok, {:error, _}] = result
  end
end
