# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :greenhouse_tycoon_web,
  generators: [context_app: :greenhouse_tycoon, binary_id: true]

# Public configuration in line with Landing Site standards
# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :greenhouse_tycoon, GreenhouseTycoon.Mailer, adapter: Swoosh.Adapters.Local

config :greenhouse_tycoon_web,
  generators: [context_app: :greenhouse_tycoon]

# Configures the endpoint
config :greenhouse_tycoon_web, GreenhouseTycoonWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: GreenhouseTycoonWeb.ErrorHTML, json: GreenhouseTycoonWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: GreenhouseTycoon.PubSub,
  live_view: [signing_salt: "eqjiL/xn"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  greenhouse_tycoon_web: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/greenhouse_tycoon_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Shared configuration for common libraries
# Individual apps configure their own ExESDB instances

# Configure ExESDB Gater (shared by all apps)
config :ex_esdb_gater, :api, pub_sub: :ex_esdb_pubsub

# ExESDB configuration is handled by individual apps
# No shared ExESDB configuration needed - each app configures its own store

# Reduce logging noise for clustering and storage libraries
config :swarm, log_level: :error
config :libcluster, log_level: :error
config :khepri, log_level: :warning
config :ra, log_level: :warning

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  greenhouse_tycoon_web: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/greenhouse_tycoon_web/assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time [$level] $metadata$message\n",
  metadata: [:mfa, :request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Shared configuration for common libraries
# Individual apps configure their own ExESDB instances

# Configure ExESDB Gater (shared by all apps)
config :ex_esdb_gater, :api, pub_sub: :ex_esdb_pubsub

# ExESDB configuration is handled by individual apps
# No shared ExESDB configuration needed - each app configures its own store

# Configure libcluster for development
# Disabled for umbrella mode - all apps run in single node
config :libcluster,
  topologies: [
    # greenhouse_tycoon: [
    #   strategy: Cluster.Strategy.Gossip,
    #   config: [
    #     port: 45_892,
    #     if_addr: "0.0.0.0",
    #     multicast_addr: "255.255.255.255",
    #     broadcast_only: true,
    #     secret: System.get_env("GH_TYC_CLUSTER_SECRET") || "gh_tyc_cluster_secret"
    #   ]
    # ]
  ]

# Configure Swarm
config :swarm,
  sync_nodes_timeout: 60_000,
  max_restarts: 3,
  max_seconds: 5

# Configure ExESDB for greenhouse_tycoon
config :greenhouse_tycoon, :ex_esdb,
  data_dir: "data/greenhouse_tycoon",
  store_id: :greenhouse_tycoon,
  timeout: 10_000,
  db_type: :single,
  pub_sub: :ex_esdb_pubsub,
  store_description: "Greenhouse Tycoon Event Store",
  store_tags: ["greenhouse_tycoon", "demo", "event-sourcing", "development"]

# Configure Commanded for greenhouse_tycoon
config :greenhouse_tycoon, GreenhouseTycoon.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :greenhouse_tycoon,
    stream_prefix: "greenhouse_tycoon_",
    serializer: Jason,
    event_type_mapper: GreenhouseTycoon.EventTypeMapper
  ],
  snapshotting: %{
    GreenhouseTycoon.Greenhouse => [
      snapshot_every: 5,
      snapshot_version: 1
    ]
  }

# Configure ExESDB Commanded Adapter
config :ex_esdb_commanded_adapter, :event_type_mapper, GreenhouseTycoon.EventTypeMapper

# Configure additional apps' Commanded integrations
# Uncomment when creating these apps:

# config :manage_crops, ManageCrops.CommandedApp,
#   event_store: [
#     adapter: ExESDB.Commanded.Adapter,
#     store_id: :manage_crops,
#     stream_prefix: "manage_crops_",
#     serializer: Jason
#   ]

# config :procure_supplies, ProcureSupplies.CommandedApp,
#   event_store: [
#     adapter: ExESDB.Commanded.Adapter,
#     store_id: :procure_supplies,
#     stream_prefix: "procure_supplies_",
#     serializer: Jason
#   ]

# config :maintain_equipment, MaintainEquipment.CommandedApp,
#   event_store: [
#     adapter: ExESDB.Commanded.Adapter,
#     store_id: :maintain_equipment,
#     stream_prefix: "maintain_equipment_",
#     serializer: Jason
#   ]

# config :manage_greenhouse, ManageGreenhouse.CommandedApp,
#   event_store: [
#     adapter: ExESDB.Commanded.Adapter,
#     store_id: :manage_greenhouse,
#     stream_prefix: "manage_greenhouse_",
#     serializer: Jason
#   ]

# config :control_equipment, ControlEquipment.CommandedApp,
#   event_store: [
#     adapter: ExESDB.Commanded.Adapter,
#     store_id: :control_equipment,
#     stream_prefix: "control_equipment_",
#     serializer: Jason
#   ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
