defmodule Kiri.Sensor.Test do
  use ExUnit.Case

  alias Kiri.Sensor

  def assert_received_sensory_signal(sensor_pid, vector_len) do
    assert_receive {^sensor_pid, :forward, sensory_signal},
                   2_000,
                   "Sensor should forward the signal to fanout PIDs"

    assert length(sensory_signal) == vector_len
  end

  test "Sensor must wait for sync message after initialization, then sense and forward the sensed signal forwards" do
    self_pid = self()
    sensor_pid = Sensor.start(self_pid, node())
    cortex_pid = self_pid
    fanout_pids = [self_pid, self_pid]
    vector_len = 2

    send(
      sensor_pid,
      {self_pid, {"sensor_id", cortex_pid, :random_number_generator, vector_len, fanout_pids}}
    )

    send(sensor_pid, {cortex_pid, :sync})

    assert_received_sensory_signal(sensor_pid, vector_len)
    assert_received_sensory_signal(sensor_pid, vector_len)
  end

  test "Sensor should terminate upon receiving the corresponding message" do
    self_pid = self()
    sensor_pid = Sensor.start(self_pid, node())
    cortex_pid = self_pid

    send(
      sensor_pid,
      {self_pid, {"sensor_id", cortex_pid, :random_number_generator, 1, []}}
    )

    send(sensor_pid, {cortex_pid, :terminate})

    :timer.sleep(1_000)

    refute Process.alive?(sensor_pid)
  end
end
