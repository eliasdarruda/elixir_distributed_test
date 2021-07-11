defmodule Dist do
  use Application

  def start(_type, _args) do
    children = [
      pg_spec(),
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
