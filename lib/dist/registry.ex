defmodule Dist.Registry do
  @moduledoc """
  Defines a distributed registry for all process
  """
  use Horde.Registry

  def child_spec() do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [%{}]}
    }
  end

  @doc false
  def start_link(_) do
    Horde.Registry.start_link(__MODULE__, [keys: :unique, members: :auto], name: __MODULE__)
  end

  @impl true
  def init(args) do
    Horde.Registry.init(args)
  end
end
