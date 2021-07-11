defmodule Dist.Item do
  use GenServer

  @impl true
  def init(args) do
    Process.flag(:trap_exit, true)

    :ok = :pg.join({args[:id], Dist.Item}, self())

    {:ok, args}
  end

  @impl true
  def terminate(_reason, [id: id] = state) do
    :ok = :pg.leave(id, self())

    {:noreply, state}
  end

  @impl true
  def handle_call(:hello_world, _from, state) do
    {:reply, {:hello_from, Node.self()}, state}
  end

  def start(args) do
    GenServer.start(__MODULE__, args)
  end
end
