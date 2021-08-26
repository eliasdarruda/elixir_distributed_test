defmodule Dist.ItemSyn do
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
    {:reply, {:hello_from, :syn}, state}
  end

  def start(args) do
    GenServer.start(__MODULE__, args, name: via(args[:id]))
  end

  def hello(id) do
    GenServer.call(via(id), :hello_world)
  end

  def via(id) do
    {:via, :syn, {id, __MODULE__}}
  end
end
