defmodule MakeProxyTest do
  use ExUnit.Case
  doctest MakeProxy

  test "greets the world" do
    assert MakeProxy.hello() == :world
  end
end
