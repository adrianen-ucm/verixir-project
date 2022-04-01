defmodule Boogiex.Theory do
  alias SmtLib.Syntax.From
  alias Boogiex.Theory.Spec

  @spec init :: From.ast()
  def init() do
    quote do
      declare_sort Term
      declare_sort Type

      declare_fun type: Term :: Type,
                  integer_val: Term :: Int,
                  boolean_val: Term :: Bool,
                  integer_lit: Int :: Term,
                  boolean_lit: Bool :: Term

      declare_const int: Type,
                    bool: Type

      assert :int != :bool

      define_fun is_integer: [x: Term] :: Bool <- :type.(:x) == :int,
                 is_boolean: [x: Term] :: Bool <- :type.(:x) == :bool

      declare_fun "_+_": [Term, Term] :: Term,
                  "_*_": [Term, Term] :: Term,
                  "_==_": [Term, Term] :: Term,
                  is_integer_: Term :: Term,
                  is_boolean_: Term :: Term
    end
  end

  @spec literal(term()) :: {atom(), atom(), atom()} | nil
  def literal(n) when is_integer(n) do
    {:is_integer, :integer_val, :integer_lit}
  end

  def literal(b) when is_boolean(b) do
    {:is_boolean, :boolean_val, :boolean_lit}
  end

  def literal(_) do
    nil
  end

  @spec function(atom()) :: {atom(), [Spec.t()]} | nil
  def function(:+) do
    {:"_+_",
     [
       %Spec{
         pre: fn [x, y] ->
           quote do
             :is_integer.(unquote(x)) && :is_integer.(unquote(y))
           end
         end,
         post: fn [x, y] ->
           quote do
             :is_integer.(:"_+_".(unquote(x), unquote(y))) &&
               :integer_val.(:"_+_".(unquote(x), unquote(y))) ==
                 :integer_val.(unquote(x)) + :integer_val.(unquote(y))
           end
         end
       }
     ]}
  end

  def function(:*) do
    {:"_*_",
     [
       %Spec{
         pre: fn [x, y] ->
           quote do
             :is_integer.(unquote(x)) && :is_integer.(unquote(y))
           end
         end,
         post: fn [x, y] ->
           quote do
             :is_integer.(:"_*_".(unquote(x), unquote(y))) &&
               :integer_val.(:"_*_".(unquote(x), unquote(y))) ==
                 :integer_val.(unquote(x)) * :integer_val.(unquote(y))
           end
         end
       }
     ]}
  end

  def function(:==) do
    {:"_==_",
     [
       %Spec{
         pre: fn [x, y] ->
           quote do
             :is_integer.(unquote(x)) && :is_integer.(unquote(y))
           end
         end,
         post: fn [x, y] ->
           quote do
             :is_boolean.(:"_==_".(unquote(x), unquote(y))) &&
               :boolean_val.(:"_==_".(unquote(x), unquote(y))) ==
                 (:integer_val.(unquote(x)) == :integer_val.(unquote(y)))
           end
         end
       },
       %Spec{
         pre: fn [x, y] ->
           quote do
             :is_boolean.(unquote(x)) && :is_boolean.(unquote(y))
           end
         end,
         post: fn [x, y] ->
           quote do
             :is_boolean.(:"_==_".(unquote(x), unquote(y))) &&
               :boolean_val.(:"_==_".(unquote(x), unquote(y))) ==
                 (:boolean_val.(unquote(x)) == :boolean_val.(unquote(y)))
           end
         end
       }
     ]}
  end

  def function(:is_integer) do
    {:is_integer_,
     [
       %Spec{
         pre: fn [_] -> true end,
         post: fn [x] ->
           quote do
             :is_boolean.(:is_integer_.(unquote(x))) &&
               :boolean_val.(:is_integer_.(unquote(x))) ==
                 :is_integer.(unquote(x))
           end
         end
       }
     ]}
  end

  def function(:is_boolean) do
    {:is_boolean_,
     [
       %Spec{
         pre: fn [_] -> true end,
         post: fn [x] ->
           quote do
             :is_boolean.(:is_boolean_.(unquote(x))) &&
               :boolean_val.(:is_boolean_.(unquote(x))) ==
                 :is_boolean.(unquote(x))
           end
         end
       }
     ]}
  end

  def function(_) do
    nil
  end
end
