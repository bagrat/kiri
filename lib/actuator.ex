defmodule Kiri.Actuator do
  alias Kiri.Actuator

  require Logger

  def start(exoself_pid, node) do
    Node.spawn(node, Actuator, :loop, [exoself_pid])
  end

  def loop(exoself_pid) do
    receive do
      {^exoself_pid, {id, cortex_pid, action_fn, fanin_pids}} ->
        loop(id, cortex_pid, action_fn, {fanin_pids, fanin_pids}, [])
    end
  end

  def loop(id, cortex_pid, action_fn, {[fanin_pid | remaining_fanin_pids], all_fanin_pids}, acc) do
    receive do
      {^fanin_pid, :forward, signal} ->
        # FIXME: understand the order of the signals
        loop(id, cortex_pid, action_fn, {remaining_fanin_pids, all_fanin_pids}, [signal | acc])

      {^cortex_pid, :terminate} ->
        :ok
    end
  end

  def loop(id, cortex_pid, action_fn, {[], all_fanin_pids}, acc) do
    apply(Actuator, action_fn, [acc])
    send(cortex_pid, {self(), :sync})
    loop(id, cortex_pid, action_fn, {all_fanin_pids, all_fanin_pids}, [])
  end

  def print_to_screen(signal) do
    Logger.info("Actuator output: #{inspect(signal)}")
    IO.puts("Actuator output: #{inspect(signal)}")
  end
end
