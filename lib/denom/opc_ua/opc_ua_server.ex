defmodule Denom.OPCUA.Server do
  @moduledoc "An OPC UA server that watches user desired variables."

  use OpcUA.Server, restart: :permanent
  alias OpcUA.{NodeId, Server, QualifiedName}
  require Logger

  defstruct opcs_pid: nil,
            address_space: nil,
            configuration: nil,
            flux_energy_node_id: nil,
            delorean_speed_node_id: nil,
            delorean_speed: 0


  def start_link(), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  # API

  def update_flux_energy(value), do: GenServer.call(__MODULE__, {:update_flux_energy, value})

  # Opc UA Server Callbacks

  def configuration(_), do: server_parameters() |> Keyword.drop([:address_space, :variable_map])

  def address_space(_), do: [
    namespace: "Sensor",

    object_node: OpcUA.ObjectNode.new(
      [
        requested_new_node_id: NodeId.new(ns_index: 2, identifier_type: "string", identifier: "Flux_Capacitor"),
        parent_node_id: NodeId.new(ns_index: 0, identifier_type: "integer", identifier: 85),
        reference_type_node_id: NodeId.new(ns_index: 0, identifier_type: "integer", identifier: 35),
        browse_name: QualifiedName.new(ns_index: 2, name: "Flux Capacitor"),
        type_definition: NodeId.new(ns_index: 0, identifier_type: "integer", identifier: 58)
      ]
    ),

    variable_node: OpcUA.VariableNode.new(
      [
        requested_new_node_id: NodeId.new(ns_index: 2, identifier_type: "string", identifier: "Flux_Energy"),
        parent_node_id: NodeId.new(ns_index: 2, identifier_type: "string", identifier: "Flux_Capacitor"),
        reference_type_node_id: NodeId.new(ns_index: 0, identifier_type: "integer", identifier: 47),
        browse_name: QualifiedName.new(ns_index: 2, name: "Flux Energy"),
        type_definition: NodeId.new(ns_index: 0, identifier_type: "integer", identifier: 63)
      ],
      write_mask: 0x3FFFFF,
      value: {10, 103.0},
      access_level: 3
    ),
    monitored_item: OpcUA.MonitoredItem.new(
      [
        monitored_item: NodeId.new(ns_index: 2, identifier_type: "string", identifier: "Flux_Energy"),
        sampling_time: 1000.0,
        subscription_id: 1
      ]
    ),

    variable_node: OpcUA.VariableNode.new(
      [
        requested_new_node_id: NodeId.new(ns_index: 2, identifier_type: "string", identifier: "DeLorean_Speed"),
        parent_node_id: NodeId.new(ns_index: 2, identifier_type: "string", identifier: "Flux_Capacitor"),
        reference_type_node_id: NodeId.new(ns_index: 0, identifier_type: "integer", identifier: 47),
        browse_name: QualifiedName.new(ns_index: 2, name: "DeLorean Speed"),
        type_definition: NodeId.new(ns_index: 0, identifier_type: "integer", identifier: 63)
      ],
      write_mask: 0x3FFFFF,
      value: {10, 0.0},
      access_level: 3
    ),
    monitored_item: OpcUA.MonitoredItem.new(
      [
        monitored_item: NodeId.new(ns_index: 2, identifier_type: "string", identifier: "DeLorean_Speed"),
        sampling_time: 1000.0,
        subscription_id: 1
      ]
    )
  ]

  # GenServer Callbacks

  def init([], opcs_pid) do
    Logger.debug("(#{__MODULE__}) Starting internal OPC UA Server...")

    :ok = Server.start(opcs_pid)

    Process.send_after(self(), :delorean_speed_update, 1000)

    %__MODULE__{
      opcs_pid: opcs_pid,
      address_space: address_space(nil),
      configuration: configuration(nil),
      flux_energy_node_id: NodeId.new(ns_index: 2, identifier_type: "string", identifier: "Flux_Energy"),
      delorean_speed_node_id: NodeId.new(ns_index: 2, identifier_type: "string", identifier: "DeLorean_Speed")
    }
  end

  defp server_parameters(), do: Application.get_env(:denom, :opc_ua_server, [config: []])

  def handle_call({:update_flux_energy, value}, _caller_info, state) do
    Server.write_node_value(state.opcs_pid, state.flux_energy_node_id, 10, value)
    {:reply, :ok, state}
  end

  def handle_info(:delorean_speed_update, state) do
    new_speed =
      with {:ok, current_speed} <- Map.fetch(state, :delorean_speed),
            new_speed <- current_speed + 1,
            # it should never travel through time.
            true <- new_speed < 80 do
        new_speed
      else
        _ ->
          Logger.debug("(#{__MODULE__}) Hit the brakes...")
          0
      end

    Server.write_node_value(state.opcs_pid, state.delorean_speed_node_id, 1, new_speed)

    Process.send_after(self(), :delorean_speed_update, 1000)

    {:noreply, %{state | delorean_speed: new_speed}}
  end
end
