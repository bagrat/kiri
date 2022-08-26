defmodule Kiri.SimpleNeuronTest do
  use ExUnit.Case
  alias Kiri.SimpleNeuron

  test "Neuron should sense and send back the result" do
    pid = SimpleNeuron.create([0.1, 0.2], 0.3)
    output = SimpleNeuron.sense(pid, [1, 2])

    assert output == [0.664036770267849]
  end

  test "Neuron output should be in the range of [-1, 1]" do
    {weights, bias} = SimpleNeuron.random_weights_and_bias()
    pid = SimpleNeuron.create(weights, bias)

    [result] = SimpleNeuron.sense(pid, [1, 2])

    assert result >= -1
    assert result <= 1
  end
end
