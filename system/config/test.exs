import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :greenhouse_tycoon, GreenhouseTycoon.Repo,
  database: Path.expand("../regulate_greenhouse_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

config :manage_crops, ManageCrops.Repo,
  database: Path.expand("../manage_crops_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

config :procure_supplies, ProcureSupplies.Repo,
  database: Path.expand("../procure_supplies_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

config :maintain_equipment, MaintainEquipment.Repo,
  database: Path.expand("../maintain_equipment_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :greenhouse_tycoon_web, GreenhouseTycoonWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "DqkAkGqUABN98FzCyPJYWjvZFkTOBSWRHc0LzV63zjacBHurOunJ9rBBPXwKm9pg",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# In test we don't send emails
config :greenhouse_tycoon, GreenhouseTycoon.Mailer, adapter: Swoosh.Adapters.Test
config :manage_crops, ManageCrops.Mailer, adapter: Swoosh.Adapters.Test
config :procure_supplies, ProcureSupplies.Mailer, adapter: Swoosh.Adapters.Test
config :maintain_equipment, MaintainEquipment.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Configure ExESDB for testing
config :ex_esdb,
  data_dir: "tmp/reg_gh_test",
  store_id: :reg_gh_test,
  timeout: 2_000,
  db_type: :single,
  pub_sub: :ex_esdb_pubsub

config :ex_esdb, :khepri,
  data_dir: "tmp/reg_gh_test",
  store_id: :reg_gh_test,
  timeout: 2_000,
  db_type: :single,
  pub_sub: :ex_esdb_pubsub

# Configure ExESDB for ManageCrops testing
config :ex_esdb, :manage_crops_test,
  data_dir: "tmp/manage_crops_test",
  store_id: :manage_crops_test,
  timeout: 2_000,
  db_type: :single,
  pub_sub: :ex_esdb_pubsub

# Configure ExESDB for ProcureSupplies testing
config :ex_esdb, :procure_supplies_test,
  data_dir: "tmp/procure_supplies_test",
  store_id: :procure_supplies_test,
  timeout: 2_000,
  db_type: :single,
  pub_sub: :ex_esdb_pubsub

# Configure ExESDB for MaintainEquipment testing
config :ex_esdb, :maintain_equipment_test,
  data_dir: "tmp/maintain_equipment_test",
  store_id: :maintain_equipment_test,
  timeout: 2_000,
  db_type: :single,
  pub_sub: :ex_esdb_pubsub

# Configure the Commanded application for testing
config :greenhouse_tycoon, GreenhouseTycoon.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :reg_gh_test,
    stream_prefix: "regulate_greenhouse_",
    serializer: Jason
  ]

config :manage_crops, ManageCrops.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :manage_crops_test,
    stream_prefix: "manage_crops_",
    serializer: Jason
  ]

config :procure_supplies, ProcureSupplies.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :procure_supplies_test,
    stream_prefix: "procure_supplies_",
    serializer: Jason
  ]

config :maintain_equipment, MaintainEquipment.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :maintain_equipment_test,
    stream_prefix: "maintain_equipment_",
    serializer: Jason
  ]

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
