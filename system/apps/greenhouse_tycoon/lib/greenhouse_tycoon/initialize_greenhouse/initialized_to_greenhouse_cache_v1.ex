defmodule GreenhouseTycoon.InitializeGreenhouse.InitializedToGreenhouseCacheV1 do
  @moduledoc """
  Subscriber that listens to greenhouse initialization PubSub events and creates entries in the cache.
  
  This subscriber follows the vertical slicing architecture by living in the same slice
  as the events it processes.
  
  Naming follows the pattern: {event}_to_{target}_cache_v{version}
  - Event: GreenhouseInitialized -> initialized
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
    Logger.info("🗄️  Starting greenhouse initialization cache subscriber")
    
    # Subscribe to projection events
    Phoenix.PubSub.subscribe(GreenhouseTycoon.PubSub, @projections_topic)
    
    {:ok, %{}}
  end
  
  # Handle greenhouse creation
  def handle_info({:greenhouse_created, read_model}, state) do
    Logger.info("🗄️  Creating greenhouse in cache: #{read_model.greenhouse_id}")
    
    case Cachex.put(@cache_name, read_model.greenhouse_id, read_model) do
      {:ok, true} ->
        Logger.info("✅ Greenhouse cached successfully: #{read_model.greenhouse_id}")
        broadcast_cache_update(:created, read_model)
        
      {:error, reason} ->
        Logger.error("❌ Failed to cache greenhouse #{read_model.greenhouse_id}: #{inspect(reason)}")
    end
    
    {:noreply, state}
  end
  
  # Ignore other messages - this subscriber only handles greenhouse creation
  def handle_info(_message, state) do
    {:noreply, state}
  end
  
  defp broadcast_cache_update(:created, read_model) do
    message = {:greenhouse_cache_created, read_model}
    
    case Phoenix.PubSub.broadcast(GreenhouseTycoon.PubSub, @cache_updates_topic, message) do
      :ok ->
        Logger.debug("📡 Cache creation broadcasted for #{read_model.greenhouse_id}")
        
      {:error, reason} ->
        Logger.warning("📡 Failed to broadcast cache creation: #{inspect(reason)}")
        # Don't fail the cache operation for broadcast failures
    end
  end
end
