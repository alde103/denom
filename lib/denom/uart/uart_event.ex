defmodule Denom.Uart.Event do
  @moduledoc "Handles the UARTs events (detects and spawns new devices)."

  use GenServer, restart: :permanent
  require Logger
  alias Denom.Uart.Device

  defmodule State do
    @moduledoc false
    defstruct reg: %{}
  end

  def ignore_devs(), do: ["ttyAMA0", "ttyS0"]

  def valid_list(:manufacturer), do: ["FTDI", "Teensyduino", "Arduino (www.arduino.cc)"]
  def valid_list(:description), do: ["USB2.0-Serial"]

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  def init(_) do
    with :ok <- NervesUEvent.subscribe([]),
         :ok <- auto_detect() do
      {:ok, %State{}}
    end
  end

  def check_uart(tty) do
    with is_valid_m <- is_valid?(tty, :manufacturer),
         is_valid_d <- is_valid?(tty, :description),
         true <- is_valid_m or is_valid_d do
      Device.Supervisor.start_child(Device, tty)
    end
  end

  def is_valid?(tty, attr) do
    Circuits.UART.enumerate()
    |> Map.get(tty)
    |> Map.get(attr)
    |> Kernel.in(valid_list(attr))
  end

  def handle_info(
        %PropertyTable.Event{value: %{"subsystem" => "tty", "devname" => devname}},
        state
      ) do
    maybe_new_tty(devname)
    {:noreply, state}
  end

  def handle_info(%PropertyTable.Event{} = uevent, state) do
    Logger.info("(#{__MODULE__}) Unhandled UEvent: #{inspect(uevent)}")
    {:noreply, state}
  end

  def maybe_new_tty("ttyUSB" <> _ = tty), do: new_tty(tty)
  def maybe_new_tty("ttyACM" <> _ = tty), do: new_tty(tty)
  def maybe_new_tty("ttyS" <> _, _), do: :ok
  def maybe_new_tty("tty" <> _, _), do: :ok

  def maybe_new_tty(unknown, _) do
    Logger.warn("(#{__MODULE__}) Unknown tty: #{inspect(unknown)}")
  end

  def new_tty(tty) do
    Logger.info("(#{__MODULE__}) Detected new UART Device: #{tty}")

    port_list =
      Circuits.UART.enumerate()
      |> Map.keys()
      |> Kernel.--(ignore_devs())

    cond do
      tty in port_list ->
        check_uart(tty)

      true ->
        Logger.info("(#{__MODULE__}) Not UART")
    end
  end

  @doc "Autodetect relevent UART Devs."
  def auto_detect() do
    Circuits.UART.enumerate()
    |> Map.keys()
    |> Kernel.--(ignore_devs())
    |> Enum.each(fn tty -> check_uart(tty) end)

    Logger.info(
      "(#{__MODULE__}) Detected UART Device already connected: #{inspect(Circuits.UART.enumerate())}"
    )
  end
end
