defmodule DenomTest do
  use ExUnit.Case
  doctest Denom

  test "greets the world" do
    assert Denom.hello() == :world
  end
end
