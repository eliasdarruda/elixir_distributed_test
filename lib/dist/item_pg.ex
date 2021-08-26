defmodule Dist.ItemPg do
  use GenServer

  @impl true
  def init(args) do
    Process.flag(:trap_exit, true)

    :ok = :pg.join({args[:id], __MODULE__}, self())

    {:ok, args}
  end

  @impl true
  def terminate(_reason, [id: id] = state) do
    :ok = :pg.leave({id, __MODULE__}, self())

    {:noreply, state}
  end

  @impl true
  def handle_call(:hello_world, _from, state) do
    {:reply, {:hello_from, :pg}, state}
  end

  def start(args) do
    GenServer.start(__MODULE__, args)
  end

  def hello(id) do
    via = via(id)

    if is_nil(via), do: IO.inspect(nil), else: GenServer.call(via, :hello_world)
  end

  def via(id) do
    :pg.get_members({id, __MODULE__}) |> List.first()
  end
end
