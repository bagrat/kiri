defmodule Kiri.SimpleNeuron do
  alias Kiri.SimpleNeuron

  require Logger

  @doc """
  Spawns a new neuron process with supplied input weights and bias in the range of [-0.5, 0.5].
  """
  def create(weights, bias) do
    Process.spawn(SimpleNeuron, :loop, [weights ++ [bias]], [])
  end

  def random_weights_and_bias() do
    {
      [:rand.uniform() - 0.5, :rand.uniform() - 0.5],
      :rand.uniform() - 0.5
    }
  end

  @doc """
  The neuron process loop that expects to receive a message containing the vector of inputs and sends the calculated output as a one element vector back to the sending process.
  """
  def loop(weights) do
    receive do
      {from, inputs} ->
        dot_product = dot(inputs, weights)
        output = [:math.tanh(dot_product)]

        Process.send(from, {:result, output}, [])

        loop(weights)
    end
  end

  defp dot(inputs, weights) do
    dot(inputs, weights, 0)
  end

  defp dot([input | rest_of_inputs], [weight | rest_of_weights], acc) do
    dot(rest_of_inputs, rest_of_weights, acc + input * weight)
  end

  defp dot([], [bias], acc) do
    acc + bias
  end

  @doc """
  The interface to send a signal to the neuron in form of a 2 element vector.
  """
  def sense(pid, [_, _] = signal) do
    Process.send(pid, {self(), signal}, [])

    receive do
      {:result, output} ->
        output
    end
  end
end
