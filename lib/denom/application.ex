defmodule Denom.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Denom.Helper, only: [supervisor_child_spec: 2, worker_child_spec: 2]

  @impl true
  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Denom.Supervisor]

    children =
      [
        # Modbus TCP Clients

        # OPC UA Server
        worker_child_spec(Denom.OPCUA.Server, []),

        # UART
        supervisor_child_spec(Denom.Uart.Supervisor, []),

        # Children for all targets
        # Starts a worker by calling: Denom.Worker.start_link(arg)
        # {Denom.Worker, arg},
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: Denom.Worker.start_link(arg)
      # {Denom.Worker, arg},
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: Denom.Worker.start_link(arg)
      # {Denom.Worker, arg},
    ]
  end

  def target() do
    Application.get_env(:denom, :target)
  end
end
