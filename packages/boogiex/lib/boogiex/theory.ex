defmodule Boogiex.Theory do
  alias Boogiex.Theory.Spec

  @spec init :: Macro.t()
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
                  integer: Term :: Term,
                  boolean: Term :: Term
    end
  end

  @spec function(atom()) :: {atom(), [Spec.t()]}
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
             :integer_val.(:"_+_".(unquote(x), unquote(y))) ==
               :integer_val.(unquote(x)) + :integer_val.(unquote(y)) &&
               :is_integer.(:"_+_".(unquote(x), unquote(y)))
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
             :integer_val.(:"_*_".(unquote(x), unquote(y))) ==
               :integer_val.(unquote(x)) * :integer_val.(unquote(y)) &&
               :is_integer.(:"_*_".(unquote(x), unquote(y)))
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
             :boolean_val.(:"_==_".(unquote(x), unquote(y)))
             <~> (:integer_val.(unquote(x)) == :integer_val.(unquote(y))) &&
               :is_boolean.(:"_==_".(unquote(x), unquote(y)))
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
             :boolean_val.(:"_==_".(unquote(x), unquote(y)))
             <~> (:boolean_val.(unquote(x)) == :boolean_val.(unquote(y))) &&
               :is_boolean.(:"_==_".(unquote(x), unquote(y)))
           end
         end
       }
     ]}
  end

  def function(:integer) do
    {:integer,
     [
       %Spec{
         pre: fn [_] -> true end,
         post: fn [x] ->
           quote do
             :is_boolean.(:integer.(unquote(x))) && :is_integer.(unquote(x))
           end
         end
       }
     ]}
  end

  def function(:boolean) do
    {:boolean,
     [
       %Spec{
         pre: fn [_] -> true end,
         post: fn [x] ->
           quote do
             :is_boolean.(:boolean.(unquote(x))) && :is_boolean.(unquote(x))
           end
         end
       }
     ]}
  end
end
