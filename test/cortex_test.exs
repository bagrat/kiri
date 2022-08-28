defmodule Kiri.Cortex.Test do
  use ExUnit.Case

  alias Kiri.Cortex

  setup %{
    num_sensors: num_sensors,
    num_actuators: num_actuators,
    num_neurons: num_neurons,
    steps_threshold: steps_threshold
  } do
    self_pid = self()

    cortex_pid = Cortex.start(self_pid, node())

    sensor_pids = for _ <- 1..num_sensors, do: self_pid
    actuator_pids = for _ <- 1..num_actuators, do: self_pid
    neuron_pids = for _ <- 1..num_neurons, do: self_pid

    send(
      cortex_pid,
      {self_pid, {"cortex_id", sensor_pids, actuator_pids, neuron_pids}, steps_threshold}
    )

    on_exit(fn ->
      case Process.alive?(cortex_pid) do
        true -> Process.exit(cortex_pid, :kill)
        _ -> :ok
      end
    end)

    %{cortex_pid: cortex_pid}
  end

  def assert_sensors_receive_sync(_, 0), do: :ok

  def assert_sensors_receive_sync(cortex_pid, num_sensors) do
    assert_receive {^cortex_pid, :sync},
                   2_000,
                   "sensor should receive sync message from cortex"

    assert_sensors_receive_sync(cortex_pid, num_sensors - 1)
  end

  @tag num_sensors: 2
  @tag num_actuators: 0
  @tag num_neurons: 0
  @tag steps_threshold: 0
  test "Cortex should send sync message to sensors after being initialized", %{
    cortex_pid: cortex_pid,
    num_sensors: num_sensors
  } do
    assert_sensors_receive_sync(cortex_pid, num_sensors)
  end

  @tag num_sensors: 2
  @tag num_actuators: 2
  @tag num_neurons: 0
  @tag steps_threshold: 2
  test "Cortex should wait for sync messages from all actuators and then re-sync sensors", %{
    cortex_pid: cortex_pid,
    num_sensors: num_sensors
  } do
    assert_sensors_receive_sync(cortex_pid, num_sensors)

    send(cortex_pid, {self(), :sync})
    send(cortex_pid, {self(), :sync})

    assert_sensors_receive_sync(cortex_pid, num_sensors)
  end

  @tag num_sensors: 1
  @tag num_actuators: 1
  @tag num_neurons: 0
  @tag steps_threshold: 2
  test "Cortex should run the sense-think-act cycle exactly specified steps threshold times",
       %{
         cortex_pid: cortex_pid,
         num_sensors: num_sensors
       } do
    assert_sensors_receive_sync(cortex_pid, num_sensors)

    send(cortex_pid, {self(), :sync})

    assert_sensors_receive_sync(cortex_pid, num_sensors)

    send(cortex_pid, {self(), :sync})

    # FIXME: the following fails, I think it's a bug, it should send a :sync message to sensors in the other non-zero step loop
    refute_receive {^cortex_pid, :sync},
                   2_000,
                   "Cortex should not re-sync after steps threshold is reached"
  end

  def assert_and_send_neurons_backup(_, 0), do: :ok

  def assert_and_send_neurons_backup(cortex_pid, num_neurons) do
    assert_receive {^cortex_pid, :get_backup}, 2_000, "neuron should receive get_backup message"

    send(cortex_pid, {self(), "neuron_#{num_neurons}", "weight_tuples_#{num_neurons}"})

    assert_and_send_neurons_backup(cortex_pid, num_neurons - 1)
  end

  def assert_exoself_received_backup(cortex_pid, num_neurons) do
    expected_backup =
      for id <- 1..num_neurons,
          do: {"neuron_#{id}", "weight_tuples_#{id}"}

    assert_receive {^cortex_pid, :backup, backup}, 2_000, "Exoself should receive neurons backup"
    assert expected_backup == backup
  end

  @tag num_sensors: 1
  @tag num_actuators: 1
  @tag num_neurons: 2
  @tag steps_threshold: 1
  test "Cortex should get backup from neurons and send to exoself",
       %{
         cortex_pid: cortex_pid,
         num_sensors: num_sensors,
         num_neurons: num_neurons
       } do
    assert_sensors_receive_sync(cortex_pid, num_sensors)

    send(cortex_pid, {self(), :sync})

    assert_and_send_neurons_backup(cortex_pid, num_neurons)
    assert_exoself_received_backup(cortex_pid, num_neurons)
  end

  @tag num_sensors: 1
  @tag num_actuators: 1
  @tag num_neurons: 1
  @tag steps_threshold: 1
  test "Cortex should terminate sensors, actuators and neurons after completion and self-terminate",
       %{
         cortex_pid: cortex_pid,
         num_sensors: num_sensors,
         num_neurons: num_neurons
       } do
    assert_sensors_receive_sync(cortex_pid, num_sensors)

    send(cortex_pid, {self(), :sync})

    assert_and_send_neurons_backup(cortex_pid, num_neurons)
    assert_exoself_received_backup(cortex_pid, num_neurons)

    assert_receive {^cortex_pid, :terminate}, 2_000, "sensors should receive terminate message"
    assert_receive {^cortex_pid, :terminate}, 2_000, "actuators should receive terminate message"
    assert_receive {^cortex_pid, :terminate}, 2_000, "neurons should receive terminate message"

    refute Process.alive?(cortex_pid)
  end
end
