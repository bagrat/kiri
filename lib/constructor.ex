defmodule Kiri.Genotype.Constructor do
  alias Kiri.Genotype

  # FIXME: why have the layer index in the neuron ID?

  def construct(sensory_fn, action_fn, hidden_layer_densities) do
    sensor = create_sensor(sensory_fn)
    actuator = create_actuator(action_fn)

    output_vector_len = actuator.vector_len
    layer_densities = hidden_layer_densities ++ [output_vector_len]

    cortex_id = {:cortex, UUID.uuid4()}

    neurons = create_layers(cortex_id, sensor, actuator, layer_densities)

    [input_layer | _] = neurons
    [output_layer | _] = Enum.reverse(neurons)

    first_layer_neuron_ids = for neuron <- input_layer, do: neuron.id
    last_layer_neuron_ids = for neuron <- output_layer, do: neuron.id
    neuron_ids = for neuron <- List.flatten(neurons), do: neuron.id

    sensor = %Genotype.Sensor{
      sensor
      | cortex_id: cortex_id,
        fanout_ids: first_layer_neuron_ids
    }

    actuator = %Genotype.Actuator{
      actuator
      | cortex_id: cortex_id,
        fanin_ids: last_layer_neuron_ids
    }

    cortex = %Genotype.Cortex{
      id: cortex_id,
      sensor_ids: [sensor.id],
      actuator_ids: [actuator.id],
      neuron_ids: neuron_ids
    }

    genotype = List.flatten([cortex, sensor, actuator | neurons])
  end

  def construct(filename, sensory_fn, action_fn, hidden_layer_densities) do
    genotype = construct(sensory_fn, action_fn, hidden_layer_densities)

    {:ok, file} = File.open(filename, [:write])

    genotype
    |> Enum.each(fn x ->
      IO.write(file, "#{inspect(x, pretty: true)}\n")
    end)

    File.close(file)
  end

  defp create_sensor(:random_number_generator) do
    %Genotype.Sensor{
      id: {:sensor, UUID.uuid4()},
      sensory_fn: :random_number_generator,
      # TODO: why static 2 for vector_len?
      vector_len: 2
    }
  end

  defp create_actuator(:print_to_screen) do
    %Genotype.Actuator{
      id: {:actuator, UUID.uuid4()},
      action_fn: :print_to_screen,
      # TODO: why static 1 for vector_len?
      vector_len: 1
    }
  end

  defp create_layers(cortex_id, sensor, actuator, layer_densities) do
    input_idps = [{sensor.id, sensor.vector_len}]
    total_layers = length(layer_densities)

    # fka FL_Neurons           fka NEXT_LDs
    [first_layer_density | next_layer_densities] = layer_densities

    neuron_ids = generate_neuron_ids(first_layer_density, 1)

    create_layers(
      cortex_id,
      actuator.id,
      1,
      total_layers,
      input_idps,
      neuron_ids,
      next_layer_densities,
      []
    )
  end

  defp create_layers(
         cortex_id,
         actuator_id,
         layer_index,
         total_layers,
         input_idps,
         neuron_ids,
         [next_layer_density | remaining_layer_densities],
         acc
       ) do
    output_neuron_ids = generate_neuron_ids(next_layer_density, layer_index + 1)
    neurons = create_layer(cortex_id, input_idps, neuron_ids, output_neuron_ids, [])

    next_input_idps = for neuron_id <- neuron_ids, do: {neuron_id, 1}

    create_layers(
      cortex_id,
      actuator_id,
      layer_index + 1,
      total_layers,
      next_input_idps,
      output_neuron_ids,
      remaining_layer_densities,
      [neurons | acc]
    )
  end

  defp create_layers(
         cortex_id,
         actuator_id,
         _total_layers,
         _total_layers,
         input_idps,
         neuron_ids,
         [],
         acc
       ) do
    output_ids = [actuator_id]
    neurons = create_layer(cortex_id, input_idps, neuron_ids, output_ids, [])

    Enum.reverse([neurons | acc])
  end

  defp create_layer(cortex_id, input_idps, [neuron_id | neuron_ids], output_ids, acc) do
    neuron = create_neuron(input_idps, neuron_id, cortex_id, output_ids)

    create_layer(cortex_id, input_idps, neuron_ids, output_ids, [neuron | acc])
  end

  defp create_layer(_cortex_id, _input_idps, [], _output_ids, acc) do
    acc
  end

  defp create_neuron(input_idps, id, cortex_id, output_ids) do
    # TODO: come up with a better name for proper_input_idps
    proper_input_idps = create_neural_input(input_idps, [])

    %Genotype.Neuron{
      id: id,
      cortex_id: cortex_id,
      activation_fn: :tanh,
      input_idps: proper_input_idps,
      output_ids: output_ids
    }
  end

  defp create_neural_input([{input_id, input_vector_length} | input_idps], acc) do
    weights = create_weights(input_vector_length, [])
    create_neural_input(input_idps, [{input_id, weights} | acc])
  end

  defp create_neural_input([], acc) do
    Enum.reverse([{:bias, :rand.uniform() - 0.5} | acc])
  end

  defp create_weights(0, acc) do
    acc
  end

  defp create_weights(length, acc) do
    weight = :rand.uniform() - 0.5
    create_weights(length - 1, [weight | acc])
  end

  defp generate_neuron_ids(num, layer_index) do
    generate_neuron_ids(num, layer_index, [])
  end

  defp generate_neuron_ids(0, _layer_index, acc) do
    acc
  end

  defp generate_neuron_ids(num, layer_index, acc) do
    id = {:neuron, {layer_index, UUID.uuid4()}}
    generate_neuron_ids(num - 1, layer_index, [id | acc])
  end
end
