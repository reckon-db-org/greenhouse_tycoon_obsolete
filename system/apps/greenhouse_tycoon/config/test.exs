import Config

# Print only warnings and errors during test
config :logger, level: :warning

# In test we don't send emails
config :greenhouse_tycoon, GreenhouseTycoon.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Configure ExESDB for GreenhouseTycoon testing
config :ex_esdb, :khepri,
  data_dir: "tmp/greenhouse_tycoon_test",
  store_id: :gh_tyc_test,
  timeout: 2_000,
  db_type: :single,
  pub_sub: :ex_esdb_pubsub,
  store_description: "Greenhouse Tycoon Test Store",
  store_tags: ["greenhouse", "tycoon", "test"]

# Configure the Commanded application for testing
config :greenhouse_tycoon, GreenhouseTycoon.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :gh_tyc_test,
    stream_prefix: "gh_tyc_",
    serializer: Jason
  ]
