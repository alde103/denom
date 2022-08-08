defmodule Denom.Helper do
  def worker_child_spec(module, args) do
    %{
      id: module,
      start: {module, :start_link, args},
      restart: :permanent,
      shutdown: 5000,
      type: :worker,
    }
  end

  def supervisor_child_spec(module, args) do
    %{
      id: module,
      start: {module, :start_link, args},
      restart: :permanent,
      shutdown: :infinity,
      type: :supervisor
    }
  end

  def spawner_child_spec(module, args) do
    %{
      id: module,
      start: {module, :start_link, args},
      restart: :transient,
      type: :worker,
    }
  end
end
