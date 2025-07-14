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

# Configure Mix tasks and generators
config :greenhouse_tycoon,
  ecto_repos: [GreenhouseTycoon.Repo]

config :manage_crops,
  ecto_repos: [ManageCrops.Repo]

config :procure_supplies,
  ecto_repos: [ProcureSupplies.Repo]

config :maintain_equipment,
  ecto_repos: [MaintainEquipment.Repo]

config :manage_greenhouse,
  ecto_repos: [ManageGreenhouse.Repo]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :greenhouse_tycoon_web,
  generators: [context_app: :greenhouse_tycoon, binary_id: true]

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

# Configure ExESDB Gater
config :ex_esdb_gater, :api, pub_sub: :ex_esdb_pubsub

# Configure the Commanded application to use ExESDB adapter
config :greenhouse_tycoon, GreenhouseTycoon.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :reg_gh,
    stream_prefix: "reg_gh_",
    serializer: Jason,
    event_type_mapper: GreenhouseTycoon.EventTypeMapper
  ]

config :manage_crops, ManageCrops.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :mng_crops,
    stream_prefix: "mng_crops_",
    serializer: Jason,
    event_type_mapper: ManageCrops.EventTypeMapper
  ]

config :procure_supplies, ProcureSupplies.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :proc_sup,
    stream_prefix: "proc_sup_",
    serializer: Jason,
    event_type_mapper: ProcureSupplies.EventTypeMapper
  ]

config :maintain_equipment, MaintainEquipment.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :maintain_equipment,
    stream_prefix: "mntn_eqpmt_",
    serializer: Jason,
    event_type_mapper: MaintainEquipment.EventTypeMapper
  ]

config :manage_greenhouse, ManageGreenhouse.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :mng_gh,
    stream_prefix: "mng_gh_",
    serializer: Jason,
    event_type_mapper: ManageGreenhouse.EventTypeMapper
  ]

# Configure the ExESDB adapter to use the event type mapper
config :ex_esdb_commanded_adapter, :event_type_mapper, GreenhouseTycoon.EventTypeMapper

# Configure libcluster for automatic cluster discovery (preferred over seed_nodes)
config :libcluster,
  topologies: [
    greenhouse_tycoon: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45_892,
        if_addr: "0.0.0.0",
        multicast_addr: "255.255.255.255",
        broadcast_only: true,
        secret: System.get_env("EX_ESDB_CLUSTER_SECRET") || "dev_cluster_secret"
      ]
    ]
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
