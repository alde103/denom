defmodule Denom.Uart.Supervisor do
  @moduledoc "Supervises UART interfaces."
  use Supervisor
  import Denom.Helper, only: [supervisor_child_spec: 2, worker_child_spec: 2]
  alias Denom.Uart

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      supervisor_child_spec(Uart.Device.Supervisor, []),
      worker_child_spec(Uart.Event, [])
    ]
    Supervisor.init(children, strategy: :one_for_one, max_restarts: 20)
  end
end
