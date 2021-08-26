defmodule Dist.SlaveNode do
  @moduledoc """
  This creates slave nodes and connects to current node
  You can limit the CPU cores by spawning with cpu_count flag
  """

  def spawn(cpu_count \\ 2) do
    # Turn node into a distributed node with the given long name
    :net_kernel.start([:"primary@127.0.0.1"])

    # Allow spawned nodes to fetch all code from this node
    :erl_boot_server.start([])
    allow_boot to_charlist("127.0.0.1")

    Task.async(fn -> spawn_node(:"n#{:rand.uniform(100_000)}@127.0.0.1", cpu_count) end)
    |> Task.await(30_000)
  end

  def cpus_online_count(node) do
    rpc(node, System, :schedulers_online, [])
  end

  def observe(node) do
    rpc(node, __MODULE__, :observer_start, [])
  end

  def heavy(node, count \\ 1_000_000) do
    rpc(node, __MODULE__, :use_cpu_heavily, [count])
  end

  def observer_start do
    :observer.start()
  end

  def use_cpu_heavily(count \\ 100_000_000) do
    1..count
    |> Flow.from_enumerable(max_demand: System.schedulers_online)
    |> Flow.map(fn n -> n * 2 end)
    |> Flow.uniq
    |> Flow.run
  end

  defp spawn_node(node_host, cpu_count) do
    {:ok, node} = :slave.start(to_charlist("127.0.0.1"), node_name(node_host), inet_loader_args(cpu_count))

    add_code_paths(node)
    transfer_configuration(node)
    ensure_applications_started(node)

    {:ok, node}
  end

  defp rpc(node, module, function, args) do
    :rpc.block_call(node, module, function, args)
  end

  defp inet_loader_args(cpu_count) do
    to_charlist("-loader inet -hosts 127.0.0.1 -setcookie #{:erlang.get_cookie()} +S #{cpu_count}")
  end

  defp allow_boot(host) do
    {:ok, ipv4} = :inet.parse_ipv4_address(host)
    :erl_boot_server.add_slave(ipv4)
  end

  defp add_code_paths(node) do
    rpc(node, :code, :add_paths, [:code.get_path()])
  end

  defp transfer_configuration(node) do
    for {app_name, _, _} <- Application.loaded_applications() do
      for {key, val} <- Application.get_all_env(app_name) do
        rpc(node, Application, :put_env, [app_name, key, val])
      end
    end
  end

  defp ensure_applications_started(node) do
    rpc(node, Application, :ensure_all_started, [:mix])
    rpc(node, Mix, :env, [Mix.env()])
    for {app_name, _, _} <- Application.loaded_applications() do
      rpc(node, Application, :ensure_all_started, [app_name])
    end
  end

  defp node_name(node_host) do
    node_host
    |> to_string
    |> String.split("@")
    |> Enum.at(0)
    |> String.to_atom
  end
end
