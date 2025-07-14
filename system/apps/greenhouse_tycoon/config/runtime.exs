import Config

# Runtime configuration only applies in production
if config_env() == :prod do
  config :logger, :console,
    format: "$time [$level] $metadata$message\n",
    metadata: [:mfa, :request_id],
    level: :info,
    # Multiple filters to reduce noise from various components
    filters: [
      ra_noise: {ExESDB.LoggerFilters, :filter_ra},
      khepri_noise: {ExESDB.LoggerFilters, :filter_khepri},
      swarm_noise: {ExESDB.LoggerFilters, :filter_swarm},
      libcluster_noise: {ExESDB.LoggerFilters, :filter_libcluster}
    ]

  # Ensure data directory exists
  data_dir = System.get_env("GH_TYC_DATA_DIR") || "/data/greenhouse_tycoon"
  File.mkdir_p!(data_dir)

  # Configure ExESDB for GreenhouseTycoon runtime
  config :ex_esdb, :khepri,
    data_dir: data_dir,
    store_id: String.to_atom(System.get_env("GH_TYC_STORE_ID") || "gh_tyc"),
    timeout: String.to_integer(System.get_env("GH_TYC_TIMEOUT") || "15000"),
    db_type: String.to_atom(System.get_env("GH_TYC_DB_TYPE") || "cluster"),
    pub_sub: String.to_atom(System.get_env("GH_TYC_PUB_SUB") || "ex_esdb_pubsub"),
    store_description: System.get_env("GH_TYC_STORE_DESCRIPTION") || "Greenhouse Tycoon Store",
    store_tags:
      (System.get_env("GH_TYC_STORE_TAGS") || "greenhouse,tycoon,production")
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

  config :ex_esdb_gater, :api,
    pub_sub: String.to_atom(System.get_env("GH_TYC_PUB_SUB") || "ex_esdb_pubsub")

  # Configure Commanded for runtime
  config :greenhouse_tycoon, GreenhouseTycoon.CommandedApp,
    event_store: [
      adapter: ExESDB.Commanded.Adapter,
      store_id: String.to_atom(System.get_env("GH_TYC_STORE_ID") || "gh_tyc"),
      stream_prefix: "gh_tyc_",
      serializer: Jason,
      event_type_mapper: GreenhouseTycoon.EventTypeMapper
    ]

  # Configure libcluster for runtime
  config :libcluster,
    topologies: [
      greenhouse_tycoon: [
        strategy: Cluster.Strategy.Gossip,
        config: [
          port: 45_892,
          if_addr: "0.0.0.0",
          multicast_addr: "255.255.255.255",
          broadcast_only: true,
          secret: System.get_env("GH_TYC_CLUSTER_SECRET") || "gh_tyc_cluster_secret"
        ]
      ]
    ]
end

config :greenhouse_tycoon, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

# Cache population configuration for production
config :greenhouse_tycoon, :populate_cache_on_startup, true
