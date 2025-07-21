import Config

config :logger, :console,
  format: "$time [$level] $metadata$message\n",
  metadata: [:mfa, :request_id],
  level: :info

# Individual apps configure their own ExESDB instances
# This umbrella runtime config only handles shared components

# Runtime configuration only applies in production
if config_env() == :prod do
  # Ensure data directory exists
  data_dir = System.get_env("GH_TYC_DATA_DIR") || "/data/greenhouse_tycoon"
  File.mkdir_p!(data_dir)

  # Configure ExESDB for greenhouse_tycoon runtime
  config :greenhouse_tycoon, :ex_esdb,
    data_dir: data_dir,
    store_id: String.to_atom(System.get_env("GH_TYC_STORE_ID") || "greenhouse_tycoon"),
    timeout: String.to_integer(System.get_env("GH_TYC_TIMEOUT") || "15000"),
    db_type: String.to_atom(System.get_env("GH_TYC_DB_TYPE") || "cluster"),
    pub_sub: String.to_atom(System.get_env("GH_TYC_PUB_SUB") || "ex_esdb_pubsub"),
    store_description: System.get_env("GH_TYC_STORE_DESCRIPTION") || "Greenhouse Tycoon Store",
    store_tags:
      (System.get_env("GH_TYC_STORE_TAGS") || "greenhouse_tycoon,production")
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

  # Configure Commanded for runtime
  config :greenhouse_tycoon, GreenhouseTycoon.CommandedApp,
    event_store: [
      adapter: ExESDB.Commanded.Adapter,
      store_id: String.to_atom(System.get_env("GH_TYC_STORE_ID") || "greenhouse_tycoon"),
      stream_prefix: "greenhouse_tycoon_",
      serializer: Jason,
      event_type_mapper: GreenhouseTycoon.EventTypeMapper
    ]

  # Configure libcluster for runtime - following the rule to use libcluster completely
  config :libcluster,
    topologies: [
      greenhouse_tycoon: [
        strategy: Cluster.Strategy.Gossip,
        config: [
          port: String.to_integer(System.get_env("GH_TYC_CLUSTER_PORT") || "45892"),
          if_addr: System.get_env("GH_TYC_CLUSTER_IF_ADDR") || "0.0.0.0",
          multicast_addr: System.get_env("GH_TYC_CLUSTER_MULTICAST_ADDR") || "255.255.255.255",
          broadcast_only: true,
          secret: System.get_env("GH_TYC_CLUSTER_SECRET") || "gh_tyc_cluster_secret"
        ]
      ]
    ]
end

# The secret key base is used to sign/encrypt cookies and other secrets.
# A default value is used in config/dev.exs and config/test.exs but you
# want to use a different value for prod and you most likely don't want
# to check this value into version control, so we use an environment
# variable instead.
secret_key_base =
  System.get_env("GH_TYC_SECRET_KEY_BASE") ||
    raise """
    environment variable GH_TYC_SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :greenhouse_tycoon_web, GreenhouseTycoonWeb.Endpoint,
  http: [
    # Enable IPv6 and bind on all interfaces.
    # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
    ip: {0, 0, 0, 0, 0, 0, 0, 0},
    port: String.to_integer(System.get_env("PORT") || "4000")
  ],
  secret_key_base: secret_key_base

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :greenhouse_tycoon_web, GreenhouseTycoonWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to your endpoint configuration:
#
#     config :greenhouse_tycoon_web, GreenhouseTycoonWeb.Endpoint,
#       https: [
#         ...,
#         port: 443,
#         cipher_suite: :strong,
#         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
#       ]
#
# The `cipher_suite` is set to `:strong` to support only the
# latest and more secure SSL ciphers. This means old browsers
# and clients may not be supported. You can set it to
# `:compatible` for wider support.
#
# `:keyfile` and `:certfile` expect an absolute path to the key
# and cert in disk or a relative path inside priv, for example
# "priv/ssl/server.key". For all supported SSL configuration
# options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
#
# We also recommend setting `force_ssl` in your config/prod.exs,
# ensuring no data is ever sent via http, always redirecting to https:
#
#     config :greenhouse_tycoon_web, GreenhouseTycoonWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Configuring the mailer
#
# In production you need to configure the mailer to use a different adapter.
# Also, you may need to configure the Swoosh API client of your choice if you
# are not using SMTP. Here is an example of the configuration:
#
#     config :greenhouse_tycoon, GreenhouseTycoon.Mailer,
#       adapter: Swoosh.Adapters.Mailgun,
#       api_key: System.get_env("MAILGUN_API_KEY"),
#       domain: System.get_env("MAILGUN_DOMAIN")
#
# For this example you need include a HTTP client required by Swoosh API client.
# Swoosh supports Hackney and Finch out of the box:
#
#     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
#
# See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

config :greenhouse_tycoon, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

# Cache population configuration for production
config :greenhouse_tycoon, :populate_cache_on_startup, true
