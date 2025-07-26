defmodule GreenhouseTycoon.MeasureHumidity.HumidityMeasuredToGreenhouseCacheV1 do
  @moduledoc """
  Subscriber that listens to humidity measurement PubSub events and updates the cache.

  This subscriber follows the vertical slicing architecture and focuses on updating the humidity measurement in the cache.

  Naming follows the pattern: {event}_to_{target}_cache_v{version}
  - Event: HumidityMeasured -> humidity_measured
  - Target: Greenhouse cache -> greenhouse_cache
  """

  use GenServer

  alias GreenhouseTycoon.ReadModels.GreenhouseReadModel

  require Logger

  @cache_name :greenhouse_read_models
  @projections_topic "greenhouse_projections"
  @cache_updates_topic "greenhouse_cache_updates"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    Logger.info("🗄️  Starting humidity measurement cache subscriber")

    # Subscribe to projection events
    Phoenix.PubSub.subscribe(GreenhouseTycoon.PubSub, @projections_topic)

    {:ok, %{}}
  end

  # Handle humidity measurements
  def handle_info({:humidity_measured, partial_read_model}, state) do
    update_cache_field(partial_read_model, :humidity_measured, fn read_model ->
      %{read_model |
        current_humidity: partial_read_model.current_humidity,
        updated_at: partial_read_model.updated_at,
        event_count: read_model.event_count + 1
      }
    end)

    {:noreply, state}
  end

  # Ignore other messages
  def handle_info(_message, state) do
    {:noreply, state}
  end

  # Update cache field with new humidity
  defp update_cache_field(partial_read_model, event_type, update_fn) do
    greenhouse_id = partial_read_model.greenhouse_id

    Logger.info("🗄️  Processing #{event_type} for cache: #{greenhouse_id}")

    case Cachex.get(@cache_name, greenhouse_id) do
      {:ok, nil} ->
        Logger.warning("🗄️  Greenhouse #{greenhouse_id} not found in cache for #{event_type}")

      {:ok, existing_read_model} ->
        updated_model = update_fn.(existing_read_model)
        updated_model = %{updated_model | status: GreenhouseReadModel.calculate_status(updated_model)}

        case Cachex.put(@cache_name, greenhouse_id, updated_model) do
          {:ok, true} ->
            Logger.info("✅ Cache updated successfully for #{greenhouse_id} (#{event_type})")
            broadcast_cache_update(:updated, updated_model, event_type)

          {:error, reason} ->
            Logger.error("❌ Failed to update cache for #{greenhouse_id}: #{inspect(reason)}")
        end

      {:error, reason} ->
        Logger.error("❌ Cache error for #{greenhouse_id}: #{inspect(reason)}")
    end
  end

  # Broadcast cache update
  defp broadcast_cache_update(operation, read_model, event_type \\ nil) do
    message = case operation do
      :updated -> {:greenhouse_cache_updated, read_model, event_type}
    end

    case Phoenix.PubSub.broadcast(GreenhouseTycoon.PubSub, @cache_updates_topic, message) do
      :ok ->
        Logger.debug("📡 Cache update broadcasted for #{read_model.greenhouse_id}")

      {:error, reason} ->
        Logger.warning("📡 Failed to broadcast cache update: #{inspect(reason)}")
        # Don't fail the cache operation for broadcast failures
    end
  end
end

