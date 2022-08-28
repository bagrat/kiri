defmodule Kiri.Actuator.Test do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Kiri.Actuator

  test "Actuator must apply the action function on the signal accumulated from the fan-in neurons and send sync message to Cortex" do
    self_pid = self()
    actuator_pid = Actuator.start(self_pid, node())
    cortex_pid = self_pid
    fanin_pids = [self_pid, self_pid]

    send(actuator_pid, {self_pid, {"actuator_id", cortex_pid, :print_to_screen, fanin_pids}})

    signals = [123, 456]

    assert capture_log(fn ->
             for signal <- signals, do: send(actuator_pid, {self_pid, :forward, signal})

             assert_receive {^actuator_pid, :sync},
                            2_000,
                            "Actuator should send sync message to Cortex after receiving all signals"
           end) =~ "#{inspect(Enum.reverse(signals))}"
  end

  test "Actuator terminates upon receiving according message from Cortex" do
    self_pid = self()
    actuator_pid = Actuator.start(self_pid, node())
    cortex_pid = self_pid

    send(actuator_pid, {self_pid, {"actuator_id", cortex_pid, :print_to_screen, [self_pid]}})

    send(actuator_pid, {cortex_pid, :terminate})

    :timer.sleep(1_000)

    refute Process.alive?(actuator_pid)
  end

  test "Actuator should not initialize with empty fan-in pids" do
    flunk("FIXME")
  end
end
