defmodule Dist.ItemsManager do
  use GenServer

  @topic __MODULE__

  require Logger

  defmodule Ref do
    defstruct [:type, :pid]
  end

  @impl true
  def init(_args) do
    Process.flag(:trap_exit, true)

    {:ok, %{}, {:continue, :add_topic}}
  end

  @impl true
  def handle_continue(:add_topic, state) do
    # NOOOOOOOO GOD PLEASE NOOOOOOOOOOO
    :timer.sleep(100)

    if :pg.get_members(@topic) == [] do
      Logger.debug "Joined manager"
      :ok = :pg.join(@topic, self())
    end

    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    :ok = :pg.leave(@topic, self())

    redistribute_state(:pg.get_members(@topic), state)

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
  def handle_call({:get_ids, type}, _from, state) do
    ids = Enum.map(state, fn
      {id, %Ref{type: ^type}} -> id
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)

    {:reply, ids, state}
  end

  @impl true
  def handle_call({:new, count}, _from, state) do
    pg = Enum.map(1..count, fn _ ->
      create_item(:pg)
    end)
    |> Map.new

    syn = Enum.map(1..count, fn _ ->
      create_item(:syn)
    end)
    |> Map.new

    horde = Enum.map(1..count, fn _ ->
      create_item(:horde)
    end)
    |> Map.new

    state = Map.merge(state, horde)
    |> Map.merge(syn)
    |> Map.merge(pg)

    {:reply, state, state}
  end

  defp create_item(type, existing_id \\ nil)
  defp create_item(:syn, existing_id) do
    id = existing_id || :rand.uniform(1_100_000_000)

    {:ok, pid} = case Dist.ItemSyn.start(id: id) do
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:ok, pid} -> {:ok, pid}
    end

    Process.monitor(pid)

    {id, %Ref{pid: pid, type: :syn}}
  end

  defp create_item(:horde, existing_id) do
    id = existing_id || :rand.uniform(1_100_000_000)

    {:ok, pid} = Dist.ItemHordeDynamicSupervisor.add(id)

    {id, %Ref{pid: pid, type: :horde}}
  end

  defp create_item(:pg, existing_id) do
    id = existing_id || :rand.uniform(1_100_000_000)

    {:ok, pid} = case Dist.ItemPg.start(id: id) do
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:ok, pid} -> {:ok, pid}
    end

    Process.monitor(pid)

    {id, %Ref{pid: pid, type: :pg}}
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
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # This act as a via getting the first member (not always the same order)
  # subscribed in manager topic
  defp via do
    :pg.get_members(@topic) |> List.first()
  end

  def new(count_each \\ 10000) do
    GenServer.call(via(), {:new, count_each}, 999_999_000)
  end

  def get_ids(type) do
    GenServer.call(via(), {:get_ids, type}, 999_999_000)
  end
end
