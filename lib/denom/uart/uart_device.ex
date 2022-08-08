defmodule Denom.Uart.Device do
  @moduledoc "A generic worker for a UART device."
  use GenServer, restart: :transient
  require Logger

  alias Denom.{Uart.Device, OPCUA}
  alias Circuits.UART

  defstruct uart_opts: nil,
            uart_pid: nil,
            device: nil,
            serial_number: nil

  def start_link(device) do
    GenServer.start_link(__MODULE__, device, [])
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  def init(device) do
    uart_opts = [
      speed: 9600,
      active: true,
      rx_framing_timeout: 10000,
      framing: {UART.Framing.Line, separator: "\r\n"}
    ]

    serial_number = UART.enumerate() |> get_in([device, :serial_number])

    {:ok, uart} = UART.start_link()
    Process.sleep(200)
    uart_response = UART.open(uart, device, uart_opts)

    state = %Device{
      device: device,
      uart_pid: uart,
      uart_opts: uart_opts,
      serial_number: serial_number,
    }

    Logger.debug("(#{__MODULE__}) New Device handled #{inspect({state, uart_response})}")

    {:ok, state}
  end

  def handle_info({:circuits_uart, device, {:error, reason}}, state) do
    Logger.warn("(#{__MODULE__}) Error with \"#{device}\": #{reason}")

    reconnect_uart(state)

    {:noreply, state}
  end

  def handle_info({:circuits_uart, device, {:partial, incomplete_json}}, state) do
    Logger.warn("(#{__MODULE__}) Timeout Received from UART (#{device}): #{incomplete_json}")
    {:noreply, state}
  end

  def handle_info({:circuits_uart, device, message}, state) do

    with  {:ok, json_map} <- Jason.decode(message),
          {:ok, new_flux_energy} <- Map.fetch(json_map, "OPC_UA"),
          :ok <- OPCUA.Server.update_flux_energy(new_flux_energy) do
      Logger.info("(#{__MODULE__}) Received (#{device}): #{inspect(json_map)}")
    else
      error ->
        Logger.warn("(#{__MODULE__}) Unhandled message (#{device}): #{inspect(error)}")
    end

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.debug("(#{__MODULE__}) Catch all: #{inspect(msg)}")
    {:noreply, state}
  end

  defp reconnect_uart(state) do
    case UART.open(state.uart_pid, state.device, state.uart_opts) do
      :ok ->
        Logger.info("(#{__MODULE__}) Reconnecting \"#{state.device}\"")

      {:error, reason} ->
        UART.close(state.uart_pid)
        Process.sleep(500)
        UART.stop(state.uart_pid)
        Process.sleep(500)

        Logger.warn("(#{__MODULE__}) Error with \"#{state.device}\": #{reason}, bye bye")
        exit(:normal)
    end
  end
end
