# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Greenhouse Tycoon is a sandbox application demonstrating ExESDB and ExESDB Commanded Adapter integration. This is an **obsolete** version that showcases CQRS/Event Sourcing architecture built with Elixir, Phoenix, and the Commanded framework using ExESDB as the event store.

The system simulates greenhouse regulation with commands for setting environmental targets and recording sensor measurements (temperature, humidity, light).

## Architecture

### Event Sourcing with Vertical Slices
This system implements a **vertical slice architecture** where each feature is completely self-contained:
- Each feature has dedicated Command, Event, CommandHandler, and EventHandler modules
- Commands follow the pattern `FeatureName.CommandV1`
- Events follow the pattern `FeatureName.EventV1`
- Event handlers use naming convention `{event}_to_{target}_v{version}`

### Key Technology Stack
- **ExESDB**: Event store backend using Khepri for distributed storage
- **Commanded**: CQRS/Event Sourcing framework for Elixir
- **Cachex**: In-memory caching for read models (no database dependencies)
- **Phoenix Framework**: Web interface and real-time features
- **Phoenix PubSub**: Real-time event broadcasting across the system
- **libcluster**: Automatic node clustering (preferred over seed_nodes mechanism)

### Umbrella Application Structure
```
system/                        # Umbrella root
├── apps/
│   ├── greenhouse_tycoon/     # Core domain logic with CQRS/ES
│   ├── greenhouse_tycoon_web/ # Phoenix web interface
│   ├── apis/                  # External API integrations (weather, geocoding)
│   └── landing_site/          # Additional web components
└── config/                    # Shared configuration
```

### Event Processing Architecture
```
Commands → Commanded App → Aggregates → Events → Event Handlers → Cachex Cache
                                              ↓
                                        Phoenix PubSub (real-time updates)
```

**Key Architectural Note**: This system uses **cache-only read models** - no database writes occur. All read models are built in-memory via Cachex from event streams.

**ReckonDB Alignment**: While this is an obsolete demonstration, it follows many ReckonDB architectural patterns. For new development or modifications, consult `../reckon_docs/` for current standards including proper vertical slicing, naming conventions, and ExESDB integration patterns.

## Common Development Commands

### Initial Setup
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

# Simple background mode (no web interface)
../start_services_simple.sh

# Full service mode with monitoring
../start_services.sh
```

### Testing
```bash
# Run all tests across umbrella apps
cd system && mix test

# Test specific application
cd system/apps/greenhouse_tycoon && mix test
cd system/apps/greenhouse_tycoon_web && mix test

# Run specific test file
cd system && mix test apps/greenhouse_tycoon/test/greenhouse_tycoon/api_test.exs

# Run specific test by line number
cd system && mix test apps/greenhouse_tycoon/test/greenhouse_tycoon/api_test.exs:7
```

### Code Quality and Formatting
```bash
# Format code (each app has its own .formatter.exs)
cd system && mix format

# Check formatting without changes
cd system/apps/greenhouse_tycoon && mix format --check-formatted

# Check dependencies
cd system && mix deps.get
```

### Production Releases
```bash
# Build release
cd system && MIX_ENV=prod mix release greenhouse_tycoon

# Build web-only release
cd system && MIX_ENV=prod mix release greenhouse_tycoon_web
```

## Event Store and Cache Management

### Core API Operations (from IEx console)
```bash
# Start IEx session
cd system && iex -S mix

# Or with Phoenix server
cd system && mix phx.server
```

```elixir
# Event handler management (current approach - post-refactoring)
GreenhouseTycoon.API.rebuild_event_handlers()   # Reset and rebuild cache from events
GreenhouseTycoon.API.get_event_handler_status() # Check cache status and counts

# Domain operations
GreenhouseTycoon.API.create_greenhouse("gh1", "My Greenhouse", "40.7128,-74.0060", "NYC", "US", 22.5, 65.0)
GreenhouseTycoon.API.set_temperature("gh1", 25.0)
GreenhouseTycoon.API.set_humidity("gh1", 70.0)
GreenhouseTycoon.API.measure_temperature("gh1", 24.8, DateTime.utc_now())
GreenhouseTycoon.API.measure_humidity("gh1", 68.5, DateTime.utc_now())

# Query current state
GreenhouseTycoon.API.get_greenhouse("gh1")
GreenhouseTycoon.API.list_greenhouses()

# Testing utilities
GreenhouseTycoon.API.reset_greenhouse("gh1")  # Clear cache entry for testing
```

## Configuration

### ExESDB Event Store Settings
- **Development**: Single node mode (`:single`), data stored in `data/greenhouse_tycoon`
- **Production**: Cluster mode (`:cluster`), configured via environment variables
- **Store ID**: `:greenhouse_tycoon` (must be unique per environment)
- **Clustering**: Uses libcluster on port 45_892 for automatic node discovery

### Environment Variables (Production)
- `EX_ESDB_DATA_DIR`: Event store data directory
- `EX_ESDB_STORE_ID`: Unique event store identifier
- `EX_ESDB_TIMEOUT`: Operation timeout in milliseconds
- `EX_ESDB_DB_TYPE`: `:single` or `:cluster`
- `EX_ESDB_CLUSTER_SECRET`: Cluster authentication secret

### Recent Architecture Changes
The system was recently refactored from manual cache services to proper Commanded event handlers (see `REFACTORING_GUIDE.md`). Key changes:

**✅ Current (post-refactoring):**
- Direct event handlers writing to Cachex cache
- Automatic snapshots every 100 events for fast recovery
- `rebuild_event_handlers()` for cache rebuilds
- Commanded-managed projection lifecycle

**❌ Deprecated (avoid these APIs):**
- `rebuild_cache()` - Use `rebuild_event_handlers()` instead
- `populate_cache()` - Automatic via event handlers
- Manual cache population services - Removed in favor of projections

## Development Patterns and Conventions

### ReckonDB Standards and Guidelines
**IMPORTANT**: For comprehensive development standards, architectural patterns, and implementation guidelines, analyze the documentation in `../reckon_docs/`:

- `architecture_guidelines.md` - Core architecture principles, vertical slicing, testing guidelines
- `naming_conventions.md` - File naming patterns, versioning, business-focused naming
- `general_implementation_guidelines.md` - Project structure, ExESDB usage, core principles
- `code_organization.md` - Detailed project structure examples
- `ex_esdb_commanded_config.md` - ExESDB and Commanded configuration patterns
- `status_management.md` - Status field management with bitwise flags
- `pubsub_architecture.md` - PubSub implementation patterns
- `monitoring_and_observability.md` - Monitoring and observability practices

These guidelines supersede any conflicting patterns and should be followed for consistency across all ReckonDB applications.

### Code Style (per user preferences)
- Use idiomatic Elixir with pattern matching over case clauses
- Prefer multiple functions over complex conditional logic
- Avoid try..rescue constructs when possible
- Favor if..then alternatives when appropriate
- Rely completely on libcluster instead of seed_nodes mechanism

### Event Handler Naming Convention
Event handlers follow strict naming patterns:
- File: `{event_name}_to_{target}_v{version}.ex`
- Module: `{EventName}To{Target}V{Version}`
- Example: `temperature_measured_to_greenhouse_cache_v1.ex`

### Command and Event Versioning
- All commands and events are versioned (V1, V2, etc.)
- Commands: `{Feature}.CommandV1`
- Events: `{Feature}.EventV1`
- This allows for schema evolution without breaking changes

### Testing Strategy
- Test aggregate logic directly (command execution and event application)
- Test API integration with proper command dispatch
- Cache-based read model testing via event handlers
- No database testing required (cache-only architecture)
- Use `reset_greenhouse/1` for test isolation

## Troubleshooting

### Cache Issues
If cache appears stale or inconsistent:
```elixir
# Check current cache status
GreenhouseTycoon.API.get_event_handler_status()

# Rebuild cache from events (this clears cache and replays all events)
GreenhouseTycoon.API.rebuild_event_handlers()

# Restart application for complete rebuild
# Event handlers automatically replay events on startup
```

### Event Store Issues
- Check ExESDB data directory permissions
- Verify cluster configuration in production environments
- Monitor disk space for event store data directory
- Use `REFACTORING_GUIDE.md` for architecture migration questions

### Development Dependencies
External API services (used by `apis` app):
- Weather data integration
- Geocoding services
- IP-based location detection

These are optional for core domain functionality testing.