# Configuration for the GreenhouseTycoon application
# This app manages the main greenhouse tycoon business logic
import Config

# Configure ExESDB for GreenhouseTycoon
config :ex_esdb, :khepri,
  data_dir: "tmp/greenhouse_tycoon",
  store_id: :gh_tyc,
  timeout: 10_000,
  db_type: :single,
  pub_sub: :ex_esdb_pubsub,
  store_description: "Greenhouse Tycoon Main Store",
  store_tags: ["greenhouse", "tycoon", "main", "development"]

# Configure the Commanded application to use ExESDB adapter
config :greenhouse_tycoon, GreenhouseTycoon.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :gh_tyc,
    stream_prefix: "gh_tyc_",
    serializer: Jason,
    event_type_mapper: GreenhouseTycoon.EventTypeMapper
  ]

# Configure the ExESDB adapter to use the event type mapper
config :ex_esdb_commanded_adapter, :event_type_mapper, GreenhouseTycoon.EventTypeMapper

# Configure ExESDB Gater for this app
config :ex_esdb_gater, :api, pub_sub: :ex_esdb_pubsub

# Configure libcluster for this app's ExESDB cluster
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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
