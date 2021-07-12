defmodule Dist.ItemHordeDynamicSupervisor do
  @moduledoc """
  The Distributed Driver.DynamicSupervisor supervises driver processes as they are created
  and terminated
  """
  use Horde.DynamicSupervisor

  def child_spec() do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [%{}]}
    }
  end

  def start_link(_) do
    Horde.DynamicSupervisor.start_link(
      __MODULE__,
      [
        shutdown: 120_000,
        strategy: :one_for_one,
        members: :auto,
        process_redistribution: :passive,
        delta_crdt_options: [{:sync_interval, 3000}]
      ],
      name: __MODULE__
    )
  end

  @impl true
  def init(args), do: Horde.DynamicSupervisor.init(args)

  @doc """
  Adds a driver to the dynamic supervisor.
  """
  def add(id) do
    child_spec = %{
      id: Dist.ItemHorde,
      start: {Dist.ItemHorde, :start_link, [id]},
      restart: :transient
    }

    case Horde.DynamicSupervisor.start_child(__MODULE__, child_spec) do
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:ok, pid} -> {:ok, pid}
    end
  end
end
