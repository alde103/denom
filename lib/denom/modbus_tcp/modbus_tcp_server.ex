defmodule Denom.ModbusTCP.Server do
  @moduledoc "A modbus server that watches user desired variables."
  use GenServer, restart: :permanent
  use Coder
  require Logger
  alias Modbux.Tcp.Server

  @target Mix.target()

  defstruct ms_pid: nil,
            cmds_map: nil,
            address_map: nil,
            stored_power: 0,
            delorean_status: 0

  def start_link(), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def update_stored_power(value), do: GenServer.call(__MODULE__, {:update_stored_power, value})

  def init([]) do
    Logger.debug("(#{__MODULE__}) Starting internal Modbus Server...")

    # Spawn Modbus Server.
    {:ok, ms_pid} =
      Server.start_link(model: address_map(), port: modbus_server_port(@target), active: true)

    {:ok, %__MODULE__{ms_pid: ms_pid}}
  end

  defp modbus_server_port(:host), do: 5020
  defp modbus_server_port(_target), do: 502

  defp slave_id(), do: 0x01

  defp power_address(), do: 40103

  defp address_map(), do: %{slave_id() => %{{:c, 1} => 0, {:hr, power_address()} => 0, {:hr, power_address() + 1} => 0}}

  #
  def handle_call({:update_stored_power, value}, _caller_info, state) when is_float(value) do
    modbus_data = decode("float32_be", value) |> binary_to_list([])
    modbus_data_hex = decode("float32_be", value) |> Base.encode16()
    Server.update(state.ms_pid, {:phr, slave_id(), power_address(), modbus_data})
    Logger.debug("(#{__MODULE__}) Updating DeLorean stored power: #{inspect({value, modbus_data_hex, modbus_data})}")
    {:reply, :ok, state}
  end

  def handle_call(_msg, _caller_info, state) do
    {:reply, :ok, state}
  end

  # DeLorean Switch handlers.
  def handle_info({:modbus_tcp, {:server_request, {:fc, 1, 1, [1]}}}, %{delorean_status: 0} = state) do
    Logger.info("(#{__MODULE__}) Starting DeLorean.....")
    {:noreply, %{state | delorean_status: 1}}
  end

  def handle_info({:modbus_tcp, {:server_request, {:fc, 1, 1, [0]}}}, %{delorean_status: 1} = state) do
    Logger.warn("(#{__MODULE__}) Stoping DeLorean.....")
    {:noreply, %{state | delorean_status: 0}}
  end

  # Catch all mailbox message.
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
