defmodule Kiri.Genotype do
  # FIXME: why have vector_len separately? Seems like it can be inferred from fanout/fanin lengths
  defmodule Sensor do
    defstruct [:id, :cortex_id, :sensory_fn, :vector_len, :fanout_ids]
  end

  defmodule Actuator do
    defstruct [:id, :cortex_id, :action_fn, :vector_len, :fanin_ids]
  end

  # FIXME: come up with a better name for input_idps
  defmodule Neuron do
    defstruct [:id, :cortex_id, :activation_fn, :input_idps, :output_ids]
  end

  defmodule Cortex do
    defstruct [:id, :sensor_ids, :actuator_ids, :neuron_ids]
  end
end
