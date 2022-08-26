defmodule Kiri.SimpleNN do
  alias Kiri.SimpleNN

  def create(environment_pid) do
    weights = [:rand.uniform() - 0.5, :rand.uniform() - 0.5, :rand.uniform() - 0.5]

    neuron_pid = spawn(SimpleNN, :neuron, [weights])
    sensor_pid = spawn(SimpleNN, :sensor, [neuron_pid])
    actuator_pid = spawn(SimpleNN, :actuator, [neuron_pid, environment_pid])

    send(neuron_pid, {:connect, sensor_pid, actuator_pid})

    spawn(SimpleNN, :cortex, [sensor_pid, neuron_pid, actuator_pid])
  end

  def neuron(weights) do
    receive do
      {:connect, sensor_pid, actuator_pid} ->
        IO.puts("Connecting neuron to sensor and actuator")
        neuron(weights, sensor_pid, actuator_pid)
    end
  end

  def neuron(weights, sensor_pid, actuator_pid) do
    receive do
      :terminate ->
        :ok

      {^sensor_pid, :forward, input} ->
        IO.puts("Received signal from sensor, propagating to actuator")
        dot_product = dot(input, weights)
        output = [:math.tanh(dot_product)]

        send(actuator_pid, {self(), :forward, output})

        neuron(weights, sensor_pid, actuator_pid)
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

  def sensor(neuron_pid) do
    receive do
      :terminate ->
        :ok

      :sync ->
        IO.puts("Sensing signal")
        sensory_signal = [:rand.uniform(), :rand.uniform()]

        send(neuron_pid, {self(), :forward, sensory_signal})

        sensor(neuron_pid)
    end
  end

  def actuator(neuron_pid, environment_pid) do
    receive do
      :terminate ->
        :ok

      {^neuron_pid, :forward, control_signal} ->
        IO.puts("Received signal from neuron, sending to environment")
        send(environment_pid, control_signal)

        actuator(neuron_pid, environment_pid)
    end
  end

  def cortex(sensor_pid, neuron_pid, actuator_pid) do
    receive do
      :sense_think_act ->
        IO.puts("Going to sense, think, act")
        send(sensor_pid, :sync)

        cortex(sensor_pid, neuron_pid, actuator_pid)

      :terminate ->
        send(sensor_pid, :terminate)
        send(sensor_pid, :terminate)
        send(actuator_pid, :terminate)

        :ok
    end
  end
end
