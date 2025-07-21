# Refactoring Guide: From Cache Services to Projections & Snapshots

## Overview

This refactoring eliminates the CachePopulation and CacheRebuildService components in favor of proper Commanded projections and snapshots. This provides a cleaner, more maintainable architecture that follows CQRS/Event Sourcing best practices.

## What Was Changed

### ✅ Added: New Event Handler Files

Created separate cache-based event handlers following the `<event_type>_to_<readmodel>.ex` pattern:

- `projections/initialized_to_greenhouse_summary.ex` - Uses `Commanded.Event.Handler`
- `projections/temperature_set_to_greenhouse_summary.ex` - Uses `Commanded.Event.Handler`
- `projections/temperature_measured_to_greenhouse_summary.ex` - Uses `Commanded.Event.Handler`
- `projections/humidity_set_to_greenhouse_summary.ex` - Uses `Commanded.Event.Handler`
- `projections/humidity_measured_to_greenhouse_summary.ex` - Uses `Commanded.Event.Handler`
- `projections/light_set_to_greenhouse_summary.ex` - Uses `Commanded.Event.Handler`
- `projections/light_measured_to_greenhouse_summary.ex` - Uses `Commanded.Event.Handler`

**Key Point**: These write **directly to the Cachex cache**, not to Ecto/database!

### ✅ Updated: CommandedApp Configuration

- Enabled `subscribe_to_all_streams?: true` for proper event handlers
- Enabled snapshots with `snapshot_every: 100` for fast rebuilds (aggregate snapshots)
- Removed manual event subscription management

### ✅ Updated: Application Supervision Tree

- Removed `GreenhouseTycoon.CachePopulationService`
- Removed `GreenhouseTycoon.Projections.EventTypeProjectionManager`
- Added new projection processes to supervision tree
- Kept `GreenhouseTycoon.CacheService` for the cache itself

## What Should Be Removed

### 🗑️ Files to Delete

1. `lib/greenhouse_tycoon/cache_population_service.ex`
2. `lib/greenhouse_tycoon/cache_rebuild_service.ex`
3. `lib/greenhouse_tycoon/projections/event_type_projection_manager.ex`
4. `lib/greenhouse_tycoon/projections/event_type_projection.ex`
5. `lib/greenhouse_tycoon/projections/handlers/` (entire directory)
6. `apps/greenhouse_tycoon/CACHE_POPULATION.md`
7. `test/cache_rebuild_test.exs`
8. `test/cache_population_service_test.exs`

### 🗑️ API Methods to Remove

From `lib/greenhouse_tycoon/api.ex`:

- `rebuild_cache/0`
- `get_cache_population_status/0`
- `populate_cache/0`
- `restart_projections/0`
- `debug_event_store/1`

### ✅ New API Methods Added

- `rebuild_event_handlers/0` - Clears cache and triggers event handler rebuilds
- `get_event_handler_status/0` - Returns cache status and greenhouse count

## Benefits of This Refactoring

### 1. **Single Source of Truth**
- Only one way to build read models: through Commanded projections
- No more dual code paths for event processing

### 2. **Direct Cache Writes**
- Event handlers write directly to Cachex cache (no database)
- Automatic snapshots for aggregates (every 100 events) for fast recovery
- Cache is rebuilt automatically on application restart from events

### 3. **Better Error Handling**
- Projection-level error handling with retry/skip logic
- Automatic restart of failed projections
- Built-in consistency guarantees

### 4. **Simplified Architecture**
- Eliminates complex manual event subscription management
- Removes custom cache population logic
- Standard Commanded patterns throughout

### 5. **Improved Performance**
- Direct cache writes (no database overhead)
- Aggregate snapshots provide faster restarts
- Commanded's optimized event processing
- Reduced startup time

## Migration Strategy

### Phase 1: Deploy New Architecture ✅ (Complete)
- New projections are now running alongside old cache services
- Both systems will populate the cache during transition

### Phase 2: Remove Old Services (Next Steps)
1. **Stop old services** by removing them from supervision tree (already done)
2. **Delete old files** listed above
3. **Update API** to remove deprecated methods
4. **Update tests** to use projection-based testing

### Phase 3: Verify and Monitor
1. **Test cache rebuilds** using `Commanded.Projections.rebuild/2`
2. **Monitor projection health** via Commanded APIs
3. **Verify snapshots** are being created correctly

## Usage Examples

### Rebuilding Event Handlers (Replaces Cache Rebuild)

```elixir
# Rebuild all event handlers (clears cache and lets event handlers rebuild automatically)
GreenhouseTycoon.API.rebuild_event_handlers()

# OR restart the application for immediate rebuild
# The event handlers will automatically replay all events and rebuild the cache
```

### Checking Event Handler Status

```elixir
# Get event handler status (returns cache status)
GreenhouseTycoon.API.get_event_handler_status()

# Example response:
# {:ok, %{
#   cache_size: 12,
#   greenhouse_count: 12,
#   greenhouse_ids: ["greenhouse1", "greenhouse2", ...],
#   status: :active,
#   timestamp: ~U[2025-07-19 02:30:00Z]
# }}
```

## Key Architectural Improvements

### Before (Complex Manual System)
```
Events → EventTypeProjectionManager → Event Handlers → Cache
         ↓
    CachePopulationService → CacheRebuildService → Event Handlers → Cache
```

### After (Clean Commanded Pattern)
```
Events → Commanded Event Handlers → Cachex Cache
```

## Conclusion

This refactoring significantly simplifies the architecture while providing better reliability, performance, and maintainability. The new system follows Commanded best practices and eliminates the need for custom cache population logic.

Data rebuilding now happens automatically through Commanded's projection system with built-in snapshotting, exactly as it should in a proper CQRS/Event Sourcing architecture.
