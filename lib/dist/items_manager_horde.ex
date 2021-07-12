defmodule Dist.ItemsManagerHorde do
  use GenServer

  @topic __MODULE__

  require Logger

  defmodule Ref do
    defstruct [:ref, :pid]
  end

  @impl true
  def init(_args) do
    Process.flag(:trap_exit, true)

    # :ok = :pg.join(@topic, self())

    {:ok, %{}}
  end

  @impl true
  def terminate(_reason, state) do
    # :ok = :pg.leave(@topic, self())

    # redistribute_state(:pg.get_members(@topic), state)

    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    Logger.debug("CHILD PROCESS IS DOWN -> #{reason}")

    # Find by ref and delete from state if necessary

    {:noreply, state}
  end

  @impl true
  def handle_cast({:add_refs, refs}, state) do
    new_refs =
      refs
      |> Enum.map(fn {key, _value} ->
        create_item(key)
      end)
      |> Map.new()

    {:noreply, Map.merge(state, new_refs)}
  end

  @impl true
  def handle_call(:new, _from, state) do
    {id, ref} = create_item()

    state = Map.put(state, id, ref)

    {:reply, state, state}
  end

  @impl true
  def handle_call({:hello, id}, _from, state) do
    case item_via(id) do
      nil ->
        {:reply, :not_found, state}

      pid ->
        {:reply, GenServer.call(pid, :hello_world), state}
    end
  end

  defp create_item(existing_id \\ nil) do
    id = existing_id || :rand.uniform(100_000_000)

    {:ok, pid} = Dist.Item.start(id: id)

    ref = Process.monitor(pid)

    {id, %Ref{pid: pid, ref: ref}}
  end

  defp redistribute_state([], refs),
    do:
      Logger.debug(
        "Redistribution Node not found, refs lost forever: #{inspect(Enum.count(refs))}"
      )

  defp redistribute_state(members, refs) do
    total_items = Enum.count(refs)
    nodes = Enum.count(members)

    # Redistribute refs evenly for every other available node
    refs
    |> Enum.chunk_every(ceil(total_items / nodes))
    |> Enum.with_index()
    |> Enum.each(fn {refs, index} ->
      member = Enum.at(members, index)
      GenServer.cast(member, {:add_refs, refs})
    end)
  end

  def start_link(args) do
    case GenServer.start_link(__MODULE__, args, name: via()) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.debug("already started at #{inspect(pid)}, returning :ignore")
        :ignore
    end
  end

  # This act as a via getting the first member (not always the same order)
  # subscribed in manager topic
  defp via do
    {:via, Horde.Registry, {Dist.Registry, __MODULE__}}
  end

  defp via_syn do
    {:via, :syn, __MODULE__}
  end

  # This also acts as a via but in finding a topic corresponding item_id and then receiving its pid
  defp item_via(item_id) do
    :pg.get_members({item_id, Dist.Item}) |> List.first()
  end

  def new do
    GenServer.call(via(), :new)
  end

  def new_syn do
    GenServer.call(via_syn(), :new)
  end

  def hello(id) do
    GenServer.call(via(), {:hello, id})
  end

  def start_item(id) do
    Horde.DynamicSupervisor.start_child(Dist.DistributedSupervisor, %{
      id: :gen_server,
      start: {Dist.Item, :start_link, [id: id]}
    })
  end
end
