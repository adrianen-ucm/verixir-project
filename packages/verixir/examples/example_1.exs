defmodule Example do
  use Verixir
  import Boogiex

  @verifier spec requires: is_integer(x),
                 ensures: is_integer(dup(x))
  defv dup(x) do
    x + x
  end

  with_local_env(
    on_error: &IO.inspect/1,
    functions:
      Module.get_attribute(
        __MODULE__,
        @verification_functions_key
      )
  ) do
    havoc d
    assume is_integer(d)
    unfold dup(d)
    assert is_integer(dup(d))
    assert dup(d) === 2 * d

    assert false, "This should fail"
  end
end
