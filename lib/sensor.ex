defmodule Kiri.Sensor do
  alias Kiri.Sensor

  require Logger

  def start(exoself_pid, node) do
    Node.spawn(node, Sensor, :loop, [exoself_pid])
  end

  def loop(exoself_pid) do
    receive do
      {^exoself_pid, {id, cortex_pid, sensory_fn, vector_len, fanout_pids}} ->
        loop(id, cortex_pid, sensory_fn, vector_len, fanout_pids)
    end
  end

  def loop(id, cortex_pid, sensory_fn, vector_len, fanout_pids) do
    receive do
      {^cortex_pid, :sync} ->
        sensory_signal = apply(Sensor, sensory_fn, [vector_len])

        for pid <- fanout_pids, do: send(pid, {self(), :forward, sensory_signal})

        loop(id, cortex_pid, sensory_fn, vector_len, fanout_pids)

      {^cortex_pid, :terminate} ->
        Logger.info("Received terminate message, terminating...")
        :ok
    end
  end

  def random_number_generator(vector_len), do: random_number_generator(vector_len, [])
  def random_number_generator(0, acc), do: acc

  def random_number_generator(vector_len, acc) do
    random_number_generator(vector_len - 1, [:rand.uniform() | acc])
  end
end
