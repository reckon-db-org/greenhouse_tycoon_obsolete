import Config

# Configure ExESDB for GreenhouseTycoon production
config :ex_esdb, :khepri,
  data_dir: "/data/greenhouse_tycoon_prod",
  store_id: :gh_tyc_prod,
  timeout: 15_000,
  db_type: :cluster,
  pub_sub: :ex_esdb_pubsub,
  store_description: "Greenhouse Tycoon Production Store",
  store_tags: ["greenhouse", "tycoon", "production"]

config :ex_esdb_gater, :api, pub_sub: :ex_esdb_pubsub

# Override Commanded configuration for production
config :greenhouse_tycoon, GreenhouseTycoon.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :gh_tyc_prod,
    stream_prefix: "gh_tyc_",
    serializer: Jason,
    event_type_mapper: GreenhouseTycoon.EventTypeMapper
  ]

# Override cluster configuration for production
config :libcluster,
  topologies: [
    greenhouse_tycoon: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45_892,
        if_addr: "0.0.0.0",
        multicast_addr: "255.255.255.255",
        broadcast_only: true,
        secret: System.get_env("GH_TYC_CLUSTER_SECRET") || "gh_tyc_prod_cluster_secret"
      ]
    ]
  ]

config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
