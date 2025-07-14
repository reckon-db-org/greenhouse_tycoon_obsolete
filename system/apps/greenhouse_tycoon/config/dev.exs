import Config

# Configure ExESDB for GreenhouseTycoon development
config :ex_esdb, :khepri,
  data_dir: "tmp/greenhouse_tycoon_dev",
  store_id: :gh_tyc_dev,
  timeout: 10_000,
  db_type: :single,
  pub_sub: :ex_esdb_pubsub,
  store_description: "Greenhouse Tycoon Development Store",
  store_tags: ["greenhouse", "tycoon", "development"]

# Ensure temp directory exists
File.mkdir_p!("tmp/greenhouse_tycoon_dev")

# Override Commanded configuration for development
config :greenhouse_tycoon, GreenhouseTycoon.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :gh_tyc_dev,
    stream_prefix: "gh_tyc_",
    serializer: Jason,
    event_type_mapper: GreenhouseTycoon.EventTypeMapper
  ]

# Override ExESDB Gater configuration for development
config :ex_esdb_gater, :api, pub_sub: :ex_esdb_pubsub

# Override cluster configuration for development
config :libcluster,
  topologies: [
    greenhouse_tycoon: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45_892,
        if_addr: "0.0.0.0",
        multicast_addr: "255.255.255.255",
        broadcast_only: true,
        secret: System.get_env("GH_TYC_CLUSTER_SECRET") || "gh_tyc_dev_cluster_secret"
      ]
    ]
  ]

config :logger,
  compile_time_purge_matching: [
    # Swarm modules - only show errors
    [module: Swarm.Distribution.Ring, level_lower_than: :error],
    [module: Swarm.Distribution.Strategy, level_lower_than: :error],
    [module: Swarm.Registry, level_lower_than: :error],
    [module: Swarm.Tracker, level_lower_than: :error],
    [module: Swarm.Distribution.StaticQuorumRing, level_lower_than: :error],
    [module: Swarm.Distribution.Handler, level_lower_than: :error],
    [module: Swarm.IntervalTreeClock, level_lower_than: :error],
    [module: Swarm.Logger, level_lower_than: :error],
    [module: Swarm, level_lower_than: :error]
  ]
