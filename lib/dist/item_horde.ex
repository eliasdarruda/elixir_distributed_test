defmodule Dist.ItemHorde do
  use GenServer

  @impl true
  def init(args) do
    Process.flag(:trap_exit, true)

    {:ok, args}
  end

  @impl true
  def terminate(_reason, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call(:hello_world, _from, state) do
    {:reply, {:hello_from, :horde}, state}
  end

  def start_link(id) do
    GenServer.start_link(__MODULE__, [id: id], name: via(id))
  end

  def hello(id) do
    GenServer.call(via(id), :hello_world)
  end

  def via(id) do
    {:via, Horde.Registry, {Dist.Registry, {id, __MODULE__}}}
  end
end
