# ExESDB App Template

This template shows how to add new ExESDB-enabled applications to the umbrella with per-app configuration.

## Steps to Add a New ExESDB App

### 1. Create the App Structure

Generate the app in the umbrella:
```bash
cd apps
mix new your_app_name --sup
```

### 2. Update mix.exs

```elixir
defmodule YourAppName.MixProject do
  use Mix.Project

  def project do
    [
      app: :your_app_name,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "config/config.exs",  # Per-app config
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {YourAppName.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_esdb, "~> 0.1.4"},
      {:ex_esdb_commanded, "0.1.3"},
      {:jason, "~> 1.2"},
      # Other dependencies...
    ]
  end
end
```

### 3. Create Config Directory and Files

Create `apps/your_app_name/config/` directory with:

#### config/config.exs
```elixir
import Config

# Configure ExESDB for YourAppName
config :ex_esdb, :khepri,
  data_dir: "tmp/your_app_name",
  store_id: :your_app_name,
  timeout: 10_000,
  db_type: :single,
  pub_sub: :ex_esdb_pubsub,
  store_description: "Your App Name Store",
  store_tags: ["your", "app", "development"]

# Configure the Commanded application to use ExESDB adapter
config :your_app_name, YourAppName.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :your_app_name,
    stream_prefix: "your_app_name_",
    serializer: Jason,
    event_type_mapper: YourAppName.EventTypeMapper
  ]

# Configure the ExESDB adapter to use the event type mapper
config :ex_esdb_commanded_adapter, :event_type_mapper, YourAppName.EventTypeMapper

# Configure ExESDB Gater for this app
config :ex_esdb_gater, :api, pub_sub: :ex_esdb_pubsub

# Configure libcluster for this app's ExESDB cluster
config :libcluster,
  topologies: [
    your_app_name: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45_893,  # Different port for each app
        if_addr: "0.0.0.0",
        multicast_addr: "255.255.255.255",
        broadcast_only: true,
        secret: System.get_env("YOUR_APP_CLUSTER_SECRET") || "your_app_cluster_secret"
      ]
    ]
  ]

# Import environment specific config
import_config "#{config_env()}.exs"
```

#### config/dev.exs
```elixir
import Config

# Configure ExESDB for YourAppName development
config :ex_esdb, :khepri,
  data_dir: "tmp/your_app_name_dev",
  store_id: :your_app_name_dev,
  timeout: 10_000,
  db_type: :single,
  pub_sub: :ex_esdb_pubsub,
  store_description: "Your App Name Development Store",
  store_tags: ["your", "app", "development"]

# Override Commanded configuration for development
config :your_app_name, YourAppName.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :your_app_name_dev,
    stream_prefix: "your_app_name_",
    serializer: Jason,
    event_type_mapper: YourAppName.EventTypeMapper
  ]

# Override cluster configuration for development
config :libcluster,
  topologies: [
    your_app_name: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45_893,
        if_addr: "0.0.0.0",
        multicast_addr: "255.255.255.255",
        broadcast_only: true,
        secret: System.get_env("YOUR_APP_CLUSTER_SECRET") || "your_app_dev_cluster_secret"
      ]
    ]
  ]
```

#### config/test.exs
```elixir
import Config

# Configure ExESDB for YourAppName testing
config :ex_esdb, :khepri,
  data_dir: "tmp/your_app_name_test",
  store_id: :your_app_name_test,
  timeout: 2_000,
  db_type: :single,
  pub_sub: :ex_esdb_pubsub,
  store_description: "Your App Name Test Store",
  store_tags: ["your", "app", "test"]

# Configure the Commanded application for testing
config :your_app_name, YourAppName.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :your_app_name_test,
    stream_prefix: "your_app_name_",
    serializer: Jason
  ]

# Print only warnings and errors during test
config :logger, level: :warning

# Disable swoosh api client
config :swoosh, :api_client, false
```

#### config/prod.exs
```elixir
import Config

# Configure ExESDB for YourAppName production
config :ex_esdb, :khepri,
  data_dir: "/data/your_app_name_prod",
  store_id: :your_app_name_prod,
  timeout: 15_000,
  db_type: :cluster,
  pub_sub: :ex_esdb_pubsub,
  store_description: "Your App Name Production Store",
  store_tags: ["your", "app", "production"]

# Override Commanded configuration for production
config :your_app_name, YourAppName.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :your_app_name_prod,
    stream_prefix: "your_app_name_",
    serializer: Jason,
    event_type_mapper: YourAppName.EventTypeMapper
  ]

# Override cluster configuration for production
config :libcluster,
  topologies: [
    your_app_name: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45_893,
        if_addr: "0.0.0.0",
        multicast_addr: "255.255.255.255",
        broadcast_only: true,
        secret: System.get_env("YOUR_APP_CLUSTER_SECRET") || "your_app_prod_cluster_secret"
      ]
    ]
  ]

config :logger, level: :info
```

#### config/runtime.exs
```elixir
import Config

config :logger, :console,
  format: "$time [$level] $metadata$message\n",
  metadata: [:mfa, :request_id],
  level: :info,
  filters: [
    ra_noise: {ExESDB.LoggerFilters, :filter_ra},
    khepri_noise: {ExESDB.LoggerFilters, :filter_khepri},
    swarm_noise: {ExESDB.LoggerFilters, :filter_swarm},
    libcluster_noise: {ExESDB.LoggerFilters, :filter_libcluster}
  ]

# Configure ExESDB for YourAppName runtime
config :ex_esdb, :khepri,
  data_dir: System.get_env("YOUR_APP_DATA_DIR") || "/data/your_app_name",
  store_id: String.to_atom(System.get_env("YOUR_APP_STORE_ID") || "your_app_name"),
  timeout: String.to_integer(System.get_env("YOUR_APP_TIMEOUT") || "15000"),
  db_type: String.to_atom(System.get_env("YOUR_APP_DB_TYPE") || "cluster"),
  pub_sub: String.to_atom(System.get_env("YOUR_APP_PUB_SUB") || "ex_esdb_pubsub"),
  store_description: System.get_env("YOUR_APP_STORE_DESCRIPTION") || "Your App Name Store",
  store_tags: (System.get_env("YOUR_APP_STORE_TAGS") || "your,app,production")
              |> String.split(",")
              |> Enum.map(&String.trim/1)
              |> Enum.reject(&(&1 == ""))

# Configure Commanded for runtime
config :your_app_name, YourAppName.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: String.to_atom(System.get_env("YOUR_APP_STORE_ID") || "your_app_name"),
    stream_prefix: "your_app_name_",
    serializer: Jason,
    event_type_mapper: YourAppName.EventTypeMapper
  ]

# Configure libcluster for runtime
config :libcluster,
  topologies: [
    your_app_name: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45_893,
        if_addr: "0.0.0.0",
        multicast_addr: "255.255.255.255",
        broadcast_only: true,
        secret: System.get_env("YOUR_APP_CLUSTER_SECRET") || "your_app_cluster_secret"
      ]
    ]
  ]
```

### 4. Create Required Modules

#### lib/your_app_name/commanded_app.ex
```elixir
defmodule YourAppName.CommandedApp do
  use Commanded.Application, otp_app: :your_app_name

  router YourAppName.Router
end
```

#### lib/your_app_name/event_type_mapper.ex
```elixir
defmodule YourAppName.EventTypeMapper do
  @moduledoc """
  Event type mapper for YourAppName
  """

  def to_string(event_type) when is_atom(event_type) do
    event_type
    |> Atom.to_string()
    |> String.replace("Elixir.", "")
  end

  def to_string(event_type) when is_binary(event_type), do: event_type

  def to_atom(event_type) when is_binary(event_type) do
    String.to_atom(event_type)
  end

  def to_atom(event_type) when is_atom(event_type), do: event_type
end
```

#### lib/your_app_name/router.ex
```elixir
defmodule YourAppName.Router do
  use Commanded.Commands.Router

  # Define your command routing here
  # dispatch YourCommand, to: YourAggregate, identity: :id
end
```

### 5. Important Configuration Notes

#### Port Allocation
Each app should use a different port for libcluster:
- `greenhouse_tycoon`: 45_892
- `manage_crops`: 45_893
- `procure_supplies`: 45_894
- `maintain_equipment`: 45_895
- etc.

#### Environment Variables
Each app should use its own environment variable prefix:
- `GH_TYC_*` for greenhouse_tycoon
- `MC_*` for manage_crops
- `PS_*` for procure_supplies
- etc.

#### Store IDs
Each app should use unique store IDs:
- Base: `:your_app_name`
- Development: `:your_app_name_dev`
- Test: `:your_app_name_test`
- Production: `:your_app_name_prod`

### 6. Benefits of This Architecture

1. **Isolation**: Each app has its own ExESDB store and configuration
2. **Scalability**: Apps can be deployed independently
3. **Flexibility**: Different apps can use different ExESDB settings
4. **Clustering**: Each app can join its own cluster or a shared cluster
5. **Environment-specific**: Different configurations per environment
6. **Runtime Configuration**: Production can use environment variables

### 7. Cross-App Communication

If apps need to communicate, they can:
1. **Shared Events**: Publish events to a common topic
2. **API Calls**: Direct API calls between apps
3. **Shared Store**: Use a shared ExESDB store for specific events
4. **Message Queues**: Use external message queues for async communication

This architecture provides the flexibility you need while maintaining proper separation of concerns.
