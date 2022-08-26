defmodule KiriTest do
  use ExUnit.Case
  doctest Kiri

  test "greets the world" do
    assert Kiri.hello() == :world
  end
end
