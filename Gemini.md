# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Greenhouse Tycoon is a sandbox application for ExESDB and ExESDB Commanded Adapter. This is an **obsolete** version that demonstrates a CQRS/Event Sourcing architecture built with Elixir, Phoenix, and the Commanded framework using ExESDB as the event store.

The system simulates greenhouse regulation with commands for setting targets and measuring environmental conditions (temperature, humidity, light).

## Architecture

### Event Sourcing with Vertical Slices
This system uses a **vertical slice architecture** where each feature is self-contained:
- Each feature has its own Command, Event, CommandHandler, and EventHandler modules
- Commands are structured as `FeatureName.CommandV1`
- Events are structured as `FeatureName.EventV1`
- Event handlers follow the pattern `{event}_to_{target}_v{version}`

### Key Components
- **ExESDB**: Event store backend using Khepri for distributed storage
- **Commanded**: CQRS/Event Sourcing framework
- **Cachex**: In-memory caching for read models (no database)
- **Phoenix PubSub**: Real-time event broadcasting
- **libcluster**: Node clustering (preferred over seed_nodes mechanism)

### Umbrella Structure
```
system/                    # Umbrella root
├── apps/
│   ├── greenhouse_tycoon/     # Core domain logic
│   ├── greenhouse_tycoon_web/ # Phoenix web interface  
│   └── apis/                  # External API integrations
└── config/                    # Shared configuration
```

### Event Processing Flow
Events → Commanded Event Handlers → Cachex Cache (no database writes)

## Common Commands

### Development Setup
```bash
cd system
mix deps.get
mix compile
```

### Running the Application
```bash
# Development server with web interface
cd system && mix phx.server
# Available at http://localhost:4000

# Simple background mode
../start_services_simple.sh

# Full service mode
../start_services.sh
```

### Testing
```bash
# Run all tests
cd system && mix test

# Run specific app tests
cd system/apps/greenhouse_tycoon && mix test
cd system/apps/greenhouse_tycoon_web && mix test

# Run specific test file
cd system && mix test apps/greenhouse_tycoon/test/greenhouse_tycoon/api_test.exs

# Run specific test
cd system && mix test apps/greenhouse_tycoon/test/greenhouse_tycoon/api_test.exs:7
```

### Code Quality
```bash
# Format code
cd system && mix format

# Check formatting (per app has .formatter.exs)
cd system/apps/greenhouse_tycoon && mix format --check-formatted
```

### Event Store Operations
```bash
# In IEx console (mix phx.server or iex -S mix)
GreenhouseTycoon.API.rebuild_event_handlers()   # Reset event handlers and rebuild cache
GreenhouseTycoon.API.get_event_handler_status() # Check cache status
GreenhouseTycoon.API.list_greenhouses()         # List cached greenhouses
```

## Configuration Notes

### ExESDB Configuration
- **Development**: Single node (`:single`), data in `data/greenhouse_tycoon`
- **Production**: Cluster mode (`:cluster`), configurable via environment variables
- Store ID: `:greenhouse_tycoon` (unique per environment)
- Uses libcluster for automatic node discovery on port 45_892

### Event Handlers
The system recently migrated from manual cache services to proper Commanded event handlers:
- Event handlers write directly to Cachex cache
- Automatic snapshots every 5 events for fast recovery
- Cache rebuilds happen via `rebuild_event_handlers()` API

### Environment Variables (Production)
- `EX_ESDB_DATA_DIR`: Data storage directory  
- `EX_ESDB_STORE_ID`: Event store identifier
- `EX_ESDB_TIMEOUT`: Operation timeout (ms)
- `EX_ESDB_DB_TYPE`: `:single` or `:cluster`
- `EX_ESDB_CLUSTER_SECRET`: Cluster authentication

## API Examples

### Core Domain Operations
```elixir
# Create greenhouse
GreenhouseTycoon.API.create_greenhouse("gh1", "My Greenhouse", "40.7128,-74.0060", "NYC", "US", 22.5, 65.0)

# Set targets  
GreenhouseTycoon.API.set_temperature("gh1", 25.0)
GreenhouseTycoon.API.set_humidity("gh1", 70.0)

# Record measurements
GreenhouseTycoon.API.measure_temperature("gh1", 24.8, DateTime.utc_now())
GreenhouseTycoon.API.measure_humidity("gh1", 68.5, DateTime.utc_now())

# Query state
GreenhouseTycoon.API.get_greenhouse("gh1")
GreenhouseTycoon.API.list_greenhouses()
```

## Important Notes

### Recent Refactoring
This system was recently refactored from manual cache services to proper Commanded projections (see REFACTORING_GUIDE.md). Some legacy API methods may still exist but should be avoided:
- ❌ `rebuild_cache()` (deprecated)
- ❌ `populate_cache()` (deprecated)  
- ✅ `rebuild_event_handlers()` (current)

### Code Style Preferences
- Use idiomatic Elixir with pattern matching over case clauses
- Prefer multiple functions over complex conditionals
- Avoid try..rescue constructs when possible
- Rely completely on libcluster instead of seed_nodes mechanism

### Testing Strategy
- Test aggregate logic directly (command execution and event application)
- Test API integration with proper command dispatch
- Cache-based read model testing via event handlers
- No database testing required (cache-only architecture)
