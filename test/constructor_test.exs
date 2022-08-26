defmodule Kiri.Genotype.Constructor.Test do
  use ExUnit.Case

  alias Kiri.Genotype
  alias Kiri.Genotype.Constructor

  test "Constructor should produce a genotype based on supplied specs" do
    genotype = Constructor.construct(:random_number_generator, :print_to_screen, [1, 3])

    assert [
             %Genotype.Cortex{
               id: {:cortex, cortex_id},
               actuator_ids: [actuator: actuator_id],
               sensor_ids: [sensor: sensor_id],
               neuron_ids: [
                 neuron: {1, neuron_1_1_id},
                 neuron: {2, neuron_2_1_id},
                 neuron: {2, neuron_2_2_id},
                 neuron: {2, neuron_2_3_id},
                 neuron: {3, neuron_3_1_id}
               ]
             },
             sensor = %Genotype.Sensor{},
             actuator = %Genotype.Actuator{}
             | neurons
           ] = genotype

    assert %Genotype.Sensor{
             id: {:sensor, ^sensor_id},
             cortex_id: {:cortex, ^cortex_id},
             sensory_fn: :random_number_generator,
             vector_len: 2,
             fanout_ids: [
               {:neuron, {1, ^neuron_1_1_id}}
             ]
           } = sensor

    assert %Genotype.Actuator{
             id: {:actuator, ^actuator_id},
             cortex_id: {:cortex, ^cortex_id},
             action_fn: :print_to_screen,
             vector_len: 1,
             fanin_ids: [
               {:neuron, {3, ^neuron_3_1_id}}
             ]
           } = actuator

    assert [
             %Genotype.Neuron{
               id: {:neuron, {1, ^neuron_1_1_id}},
               cortex_id: {:cortex, ^cortex_id},
               activation_fn: :tanh,
               input_idps: [
                 {{:sensor, ^sensor_id}, [_, _]},
                 {:bias, _}
               ],
               output_ids: [
                 neuron: {2, ^neuron_2_3_id},
                 neuron: {2, ^neuron_2_2_id},
                 neuron: {2, ^neuron_2_1_id}
               ]
             },
             %Genotype.Neuron{
               id: {:neuron, {2, ^neuron_2_1_id}},
               cortex_id: {:cortex, ^cortex_id},
               activation_fn: :tanh,
               input_idps: [
                 {{:neuron, {1, ^neuron_1_1_id}}, [_]},
                 {:bias, _}
               ],
               output_ids: [neuron: {3, ^neuron_3_1_id}]
             },
             %Genotype.Neuron{
               id: {:neuron, {2, ^neuron_2_2_id}},
               cortex_id: {:cortex, ^cortex_id},
               activation_fn: :tanh,
               input_idps: [
                 {{:neuron, {1, ^neuron_1_1_id}}, [_]},
                 {:bias, _}
               ],
               output_ids: [neuron: {3, ^neuron_3_1_id}]
             },
             %Genotype.Neuron{
               id: {:neuron, {2, ^neuron_2_3_id}},
               cortex_id: {:cortex, ^cortex_id},
               activation_fn: :tanh,
               input_idps: [
                 {{:neuron, {1, ^neuron_1_1_id}}, [_]},
                 {:bias, _}
               ],
               output_ids: [neuron: {3, ^neuron_3_1_id}]
             },
             %Genotype.Neuron{
               id: {:neuron, {3, ^neuron_3_1_id}},
               cortex_id: {:cortex, ^cortex_id},
               activation_fn: :tanh,
               input_idps: [
                 {{:neuron, {2, ^neuron_2_3_id}}, [_]},
                 {{:neuron, {2, ^neuron_2_2_id}}, [_]},
                 {{:neuron, {2, ^neuron_2_1_id}}, [_]},
                 {:bias, _}
               ],
               output_ids: [actuator: ^actuator_id]
             }
           ] = neurons
  end
end
