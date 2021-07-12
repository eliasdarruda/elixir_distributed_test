use Mix.Config

config :logger, level: :debug

config :libcluster,
  topologies: [
    local: [
      strategy: Cluster.Strategy.Gossip
    ]
  ]
