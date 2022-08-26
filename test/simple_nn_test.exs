defmodule Kiri.SimpleNN.Test do
  use ExUnit.Case
  alias Kiri.SimpleNN

  test "Simple Neural Network should sense, think and then act, sending the output to the environment" do
    cortex = SimpleNN.create(self())

    send(cortex, :sense_think_act)

    assert_receive _, 1_000, "Should have received a message from actuator"
  end
end
