defmodule GreenhouseTycoon.Repl do
  @moduledoc """
  REPL utilities for debugging GreenhouseTycoon issues.
  
  Usage in IEx:
  
      iex> alias GreenhouseTycoon.Repl
      iex> Repl.check_event_type_mapper()
      iex> Repl.check_projections()
      iex> Repl.check_cache()
      iex> Repl.create_test_greenhouse("test123")
      iex> Repl.debug_greenhouse_creation("test456")
  """
  
  require Logger
  
  alias GreenhouseTycoon.{API, CommandedApp, EventTypeMapper}
  alias GreenhouseTycoon.Events.GreenhouseInitialized
  alias GreenhouseTycoon.Commands.InitializeGreenhouse
  
  @doc """
  Check if the event type mapper is working correctly.
  """
  def check_event_type_mapper do
    Logger.info("=== Event Type Mapper Check ===")
    
    # Test mapping from module to event type
    module_name = "Elixir.GreenhouseTycoon.Events.GreenhouseInitialized"
    mapped_type = EventTypeMapper.to_event_type(module_name)
    Logger.info("Module name: #{module_name}")
    Logger.info("Mapped to: #{mapped_type}")
    
    # Test reverse mapping
    reverse_mapped = EventTypeMapper.from_event_type(mapped_type)
    Logger.info("Reverse mapped: #{reverse_mapped}")
    
    # Check all mappings
    Logger.info("All mappings:")
    EventTypeMapper.mappings() |> Enum.each(fn {module, event_type} ->
      Logger.info("  #{module} -> #{event_type}")
    end)
    
    %{
      module_name: module_name,
      mapped_type: mapped_type,
      reverse_mapped: reverse_mapped,
      mappings: EventTypeMapper.mappings()
    }
  end
  
  @doc """
  Check the status of projections.
  """
  def check_projections do
    Logger.info("=== Projection Status Check ===")
    
    case GreenhouseTycoon.Projections.EventTypeProjectionManager.status() do
      projections when is_list(projections) ->
        Logger.info("Found #{length(projections)} projections:")
        Enum.each(projections, fn projection ->
          case projection do
            {event_type, status} ->
              Logger.info("  #{event_type}: #{inspect(status)}")
            {event_type, status, opts} ->
              Logger.info("  #{event_type}: #{inspect(status)} #{inspect(opts)}")
            other ->
              Logger.info("  #{inspect(other)}")
          end
        end)
        projections
      error ->
        Logger.error("Error getting projection status: #{inspect(error)}")
        error
    end
  end
  
  @doc """
  Check the cache status.
  """
  def check_cache do
    Logger.info("=== Cache Status Check ===")
    
    case Cachex.stats(:greenhouse_read_models) do
      {:ok, stats} ->
        Logger.info("Cache stats: #{inspect(stats)}")
        stats
      error ->
        Logger.error("Error getting cache stats: #{inspect(error)}")
        error
    end
  end
  
  @doc """
  List all cache entries.
  """
  def list_cache_entries do
    Logger.info("=== Cache Entries ===")
    
    case Cachex.keys(:greenhouse_read_models) do
      {:ok, keys} ->
        Logger.info("Cache keys: #{inspect(keys)}")
        
        Enum.each(keys, fn key ->
          case Cachex.get(:greenhouse_read_models, key) do
            {:ok, value} ->
              Logger.info("  #{key}: #{inspect(value)}")
            error ->
              Logger.error("  #{key}: Error - #{inspect(error)}")
          end
        end)
        
        keys
      error ->
        Logger.error("Error getting cache keys: #{inspect(error)}")
        error
    end
  end
  
  @doc """
  Create a test greenhouse with detailed logging.
  """
  def create_test_greenhouse(greenhouse_id) do
    Logger.info("=== Creating Test Greenhouse: #{greenhouse_id} ===")
    
    result = API.create_greenhouse(
      greenhouse_id,
      greenhouse_id,
      "50.0,4.0",
      "Brussels",
      "Belgium"
    )
    
    Logger.info("Creation result: #{inspect(result)}")
    
    # Wait a bit and check cache
    :timer.sleep(1000)
    
    case Cachex.get(:greenhouse_read_models, greenhouse_id) do
      {:ok, nil} ->
        Logger.warning("Greenhouse #{greenhouse_id} not found in cache")
      {:ok, greenhouse} ->
        Logger.info("Greenhouse #{greenhouse_id} found in cache: #{inspect(greenhouse)}")
      error ->
        Logger.error("Error checking cache for #{greenhouse_id}: #{inspect(error)}")
    end
    
    result
  end
  
  @doc """
  Debug the greenhouse creation process step by step.
  """
  def debug_greenhouse_creation(greenhouse_id) do
    Logger.info("=== Debugging Greenhouse Creation: #{greenhouse_id} ===")
    
    # Step 1: Check event type mapper
    Logger.info("Step 1: Checking event type mapper")
    check_event_type_mapper()
    
    # Step 2: Check projections
    Logger.info("Step 2: Checking projections")
    check_projections()
    
    # Step 3: Check cache before creation
    Logger.info("Step 3: Checking cache before creation")
    check_cache()
    
    # Step 4: Create greenhouse
    Logger.info("Step 4: Creating greenhouse")
    result = create_test_greenhouse(greenhouse_id)
    
    # Step 5: Check cache after creation
    Logger.info("Step 5: Checking cache after creation")
    :timer.sleep(2000)  # Wait a bit longer
    check_cache()
    list_cache_entries()
    
    result
  end
  
  @doc """
  Check the Commanded app configuration.
  """
  def check_commanded_config do
    Logger.info("=== Commanded App Configuration ===")
    
    # Get the application configuration
    config = Application.get_env(:greenhouse_tycoon, GreenhouseTycoon.CommandedApp)
    Logger.info("Commanded app config: #{inspect(config)}")
    
    # Check if event type mapper is configured
    event_store_config = config[:event_store] || []
    event_type_mapper = event_store_config[:event_type_mapper]
    Logger.info("Event type mapper configured: #{inspect(event_type_mapper)}")
    
    config
  end
  
  @doc """
  Test the event type mapper directly with a real event.
  """
  def test_event_type_mapping do
    Logger.info("=== Testing Event Type Mapping ===")
    
    # Create a sample event
    event = %GreenhouseInitialized{
      greenhouse_id: "test",
      name: "test",
      location: "50.0,4.0",
      city: "Brussels",
      country: "Belgium",
      created_at: DateTime.utc_now()
    }
    
    # Test direct mapping
    module_name = event.__struct__ |> to_string()
    mapped_type = EventTypeMapper.to_event_type(module_name)
    
    Logger.info("Event struct: #{inspect(event)}")
    Logger.info("Module name: #{module_name}")
    Logger.info("Mapped type: #{mapped_type}")
    
    %{
      event: event,
      module_name: module_name,
      mapped_type: mapped_type
    }
  end
  
  @doc """
  Get all greenhouse IDs from the API.
  """
  def list_greenhouses do
    Logger.info("=== Listing Greenhouses ===")
    
    greenhouse_ids = API.list_greenhouses()
    Logger.info("Found greenhouse IDs: #{inspect(greenhouse_ids)}")
    
    greenhouse_ids
  end
  
  @doc """
  Get detailed information about a specific greenhouse.
  """
  def get_greenhouse_info(greenhouse_id) do
    Logger.info("=== Greenhouse Info: #{greenhouse_id} ===")
    
    case API.get_greenhouse_state(greenhouse_id) do
      {:ok, state} ->
        Logger.info("Greenhouse state: #{inspect(state)}")
        state
      {:error, reason} ->
        Logger.error("Error getting greenhouse state: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
