defmodule Denom.Uart.Device.Supervisor do
  @moduledoc "Supervises all UART devices."
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(module, args) do
    DynamicSupervisor.start_child(__MODULE__, {module, args})
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
