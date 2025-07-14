# ExESDB Configuration for Greenhouse Tycoon

This document explains how ExESDB is configured for the Greenhouse Tycoon system.

## Overview

ExESDB is configured as the event store for the Greenhouse Tycoon system, providing distributed event sourcing capabilities through the Commanded framework.

## Configuration Structure

### Main Configuration (`config/config.exs`)

The main configuration includes:

```elixir
# Configure ExESDB store
config :ex_esdb, :khepri,
  data_dir: "tmp/greenhouse_tycoon",
  store_id: :gh_tyc,
  timeout: 10_000,
  db_type: :single,
  pub_sub: :ex_esdb_pubsub,
  store_description: "Greenhouse Tycoon Event Store",
  store_tags: ["greenhouse", "tycoon", "development"]

# Configure the Commanded application to use ExESDB adapter
config :greenhouse_tycoon, GreenhouseTycoon.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :gh_tyc,
    stream_prefix: "gh_tyc_",
    serializer: Jason,
    event_type_mapper: GreenhouseTycoon.EventTypeMapper
  ]
```

### Environment-Specific Configurations

#### Development (`config/dev.exs`)
- **store_id**: `:gh_tyc_dev`
- **data_dir**: `"tmp/greenhouse_tycoon_dev"`
- **db_type**: `:single`
- **timeout**: `10_000`

#### Production (`config/prod.exs`)
- **store_id**: `:gh_tyc_prod`
- **data_dir**: `"/data/greenhouse_tycoon_prod"`
- **db_type**: `:cluster`
- **timeout**: `15_000`

#### Test (`config/test.exs`)
- **store_id**: `:gh_tyc_test`
- **data_dir**: `"tmp/greenhouse_tycoon_test"`
- **db_type**: `:single`
- **timeout**: `2_000`

### Runtime Configuration (`config/runtime.exs`)

The runtime configuration supports environment variables:

```elixir
config :ex_esdb, :khepri,
  data_dir: System.get_env("EX_ESDB_DATA_DIR") || "/data/greenhouse_tycoon",
  store_id: String.to_atom(System.get_env("EX_ESDB_STORE_ID") || "gh_tyc"),
  timeout: String.to_integer(System.get_env("EX_ESDB_TIMEOUT") || "15000"),
  db_type: String.to_atom(System.get_env("EX_ESDB_DB_TYPE") || "cluster"),
  pub_sub: String.to_atom(System.get_env("EX_ESDB_PUB_SUB") || "ex_esdb_pubsub"),
  store_description: System.get_env("EX_ESDB_STORE_DESCRIPTION") || "Greenhouse Tycoon Store",
  store_tags: (System.get_env("EX_ESDB_STORE_TAGS") || "greenhouse,tycoon,production")
              |> String.split(",")
              |> Enum.map(&String.trim/1)
              |> Enum.reject(&(&1 == ""))
```

## Configuration Parameters

### Core Parameters

- **`data_dir`**: Directory where ExESDB stores its data
- **`store_id`**: Unique identifier for the event store
- **`timeout`**: Timeout for operations in milliseconds
- **`db_type`**: Database type (`:single` or `:cluster`)
- **`pub_sub`**: PubSub system name

### Metadata Parameters

- **`store_description`**: Human-readable description for operational visibility
- **`store_tags`**: Tags for categorization and filtering

### Commanded Integration

- **`adapter`**: Always `ExESDB.Commanded.Adapter`
- **`stream_prefix`**: Prefix for event streams
- **`serializer`**: JSON serialization (uses Jason)
- **`event_type_mapper`**: Maps event types for storage

## Environment Variables

The following environment variables can be used in production:

| Variable | Default | Description |
|----------|---------|-------------|
| `EX_ESDB_DATA_DIR` | `/data/greenhouse_tycoon` | Data directory |
| `EX_ESDB_STORE_ID` | `gh_tyc` | Store identifier |
| `EX_ESDB_TIMEOUT` | `15000` | Timeout in milliseconds |
| `EX_ESDB_DB_TYPE` | `cluster` | Database type |
| `EX_ESDB_PUB_SUB` | `ex_esdb_pubsub` | PubSub name |
| `EX_ESDB_STORE_DESCRIPTION` | `Greenhouse Tycoon Store` | Store description |
| `EX_ESDB_STORE_TAGS` | `greenhouse,tycoon,production` | Comma-separated tags |
| `EX_ESDB_CLUSTER_SECRET` | `dev_cluster_secret` | Cluster security secret |

## Future App Configurations

When adding new apps to the system, uncomment and customize the appropriate configuration blocks in `config/config.exs`:

```elixir
# Example for manage_crops app
config :manage_crops, ManageCrops.CommandedApp,
  event_store: [
    adapter: ExESDB.Commanded.Adapter,
    store_id: :manage_crops,
    stream_prefix: "manage_crops_",
    serializer: Jason
  ]
```

Available app configurations (commented out):
- `manage_crops`
- `procure_supplies`
- `maintain_equipment`
- `manage_greenhouse`
- `control_equipment`

## Clustering Configuration

ExESDB uses libcluster for automatic node discovery:

```elixir
config :libcluster,
  topologies: [
    ex_esdb_cluster: [
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
```

This configuration follows the user's preference to rely completely on libcluster instead of the seed_nodes mechanism.

## Logging Configuration

ExESDB includes noise reduction filters for various distributed systems components:

```elixir
config :logger, :console,
  filters: [
    ra_noise: {ExESDB.LoggerFilters, :filter_ra},
    khepri_noise: {ExESDB.LoggerFilters, :filter_khepri},
    swarm_noise: {ExESDB.LoggerFilters, :filter_swarm},
    libcluster_noise: {ExESDB.LoggerFilters, :filter_libcluster}
  ]
```

## Verification

After configuration, verify the setup by:

1. **Compilation**: Run `mix compile` to ensure no configuration errors
2. **Tests**: Run `mix test` to verify the event store is working
3. **Server Start**: Run `mix phx.server` to check the system starts correctly

The system should now be properly configured to use ExESDB as its event store with appropriate settings for each environment.
