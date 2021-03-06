defmodule Dist do
  use Application

  @topologies Application.compile_env(:libcluster, :topologies)

  def start(_type, _args) do
    children = [
      {Cluster.Supervisor, [@topologies, [name: Dist.ClusterSupervisor]]},
      pg_spec(),
      Dist.Registry.child_spec(),
      Dist.ItemHordeDynamicSupervisor,
      Dist.ItemsManager
    ]

    opts = [strategy: :one_for_one, name: Dist.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp pg_spec() do
    %{
      id: :pg,
      start: {:pg, :start_link, []}
    }
  end
end
