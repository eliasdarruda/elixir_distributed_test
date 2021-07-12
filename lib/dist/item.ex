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

  def start(args) do
    GenServer.start(__MODULE__, args, name: via(args[:id]))
  end

  def hello(id) do
    GenServer.call(via(id), :hello_world)
  end

  def via(id) do
    {:via, Horde.Registry, {Dist.Registry, {id, __MODULE__}}}
  end
end

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
