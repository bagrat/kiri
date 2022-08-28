defmodule Kiri.Cortex do
  alias Kiri.Cortex

  require Logger

  def start(exoself_pid, node) do
    Node.spawn(node, Cortex, :loop, [exoself_pid])
  end

  def loop(exoself_pid) do
    receive do
      {^exoself_pid, {id, sensor_pids, actuator_pids, neuron_pids}, steps_threshold} ->
        Process.put(:start_time, DateTime.utc_now())

        for sensor_pid <- sensor_pids do
          send(sensor_pid, {self(), :sync})
        end

        loop(
          id,
          exoself_pid,
          sensor_pids,
          {actuator_pids, actuator_pids},
          neuron_pids,
          steps_threshold
        )
    end
  end

  def loop(
        id,
        exoself_pid,
        sensor_pids,
        {_pending_actuator_pids, all_actuator_pids},
        neuron_pids,
        0
      ) do
    time_elapsed = DateTime.diff(DateTime.utc_now(), Process.get(:start_time))

    Logger.info("Cortex #{id} is backing up and terminating. Total time elasped: #{time_elapsed}")

    neuron_weights_by_id = get_neuron_weights_backup(neuron_pids, [])
    send(exoself_pid, {self(), :backup, neuron_weights_by_id})

    for sensor_pid <- sensor_pids, do: send(sensor_pid, {self(), :terminate})
    for actuator_pid <- all_actuator_pids, do: send(actuator_pid, {self(), :terminate})
    for neuron_pid <- neuron_pids, do: send(neuron_pid, {self(), :terminate})
  end

  def loop(
        id,
        exoself_pid,
        sensor_pids,
        {[pending_actuator_pid | pending_actuator_pids], all_actuator_pids},
        neuron_pids,
        steps_remaining
      ) do
    receive do
      {^pending_actuator_pid, :sync} ->
        loop(
          id,
          exoself_pid,
          sensor_pids,
          {pending_actuator_pids, all_actuator_pids},
          neuron_pids,
          steps_remaining
        )

      :terminate ->
        Logger.info("Cortex #{id} is terminating")

        for sensor_pid <- sensor_pids, do: send(sensor_pid, {self(), :terminate})
        for actuator_pid <- all_actuator_pids, do: send(actuator_pid, {self(), :terminate})
        for neuron_pid <- neuron_pids, do: send(neuron_pid, {self(), :terminate})
    end
  end

  def loop(
        id,
        exoself_pid,
        sensor_pids,
        {[], all_actuator_pids},
        neuron_pids,
        steps_remaining
      ) do
    for sensor_pid <- sensor_pids, do: send(sensor_pid, {self(), :sync})

    loop(
      id,
      exoself_pid,
      sensor_pids,
      {all_actuator_pids, all_actuator_pids},
      neuron_pids,
      steps_remaining - 1
    )
  end

  def get_neuron_weights_backup([neuron_pid | remaining_neuron_pids], acc) do
    send(neuron_pid, {self(), :get_backup})

    receive do
      {^neuron_pid, neuron_id, weight_tuples} ->
        get_neuron_weights_backup(remaining_neuron_pids, [{neuron_id, weight_tuples} | acc])
    end
  end

  def get_neuron_weights_backup([], acc), do: acc
end
