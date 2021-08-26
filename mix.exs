defmodule Dist.MixProject do
  use Mix.Project

  def project do
    [
      app: :dist,
      version: "0.1.0",
      elixir: "~> 1.12",
      config_path: "./config/config.exs",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Dist, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libcluster, "~> 3.3"},
      {:benchee, "~> 1.0"},
      {:syn, "~> 2.1"},
      {:horde, "~> 0.8"},
      {:flow, "~> 1.1"}
    ]
  end
end
