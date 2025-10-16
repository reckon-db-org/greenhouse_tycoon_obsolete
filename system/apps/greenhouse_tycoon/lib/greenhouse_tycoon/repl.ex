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
  alias GreenhouseTycoon.InitializeGreenhouse.{CommandV1, EventV1}
  
  @doc """
  Check if the event type mapper is working correctly.
  """
  def check_event_type_mapper do
    Logger.info("=== Event Type Mapper Check ===")
    
    # Test mapping from module to event type
    module_name = GreenhouseTycoon.InitializeGreenhouse.EventV1
    mapped_type = EventTypeMapper.to_event_type(module_name)
    Logger.info("Module: #{inspect(module_name)}")
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
  Check the database for greenhouses.
  """
  def check_database do
    Logger.info("=== Database Status Check ===")
    
    greenhouses = GreenhouseTycoon.Repo.all(GreenhouseTycoon.Greenhouse)
    Logger.info("Found #{length(greenhouses)} greenhouses in database")
    
    Enum.each(greenhouses, fn greenhouse ->
      Logger.info("  #{greenhouse.greenhouse_id}: #{greenhouse.name}")
    end)
    
    greenhouses
  end
  
  @doc """
  List all greenhouse records from database.
  """
  def list_database_entries do
    Logger.info("=== Database Entries ===")
    
    greenhouses = GreenhouseTycoon.Repo.all(GreenhouseTycoon.Greenhouse)
    
    Enum.each(greenhouses, fn greenhouse ->
      Logger.info("  #{greenhouse.greenhouse_id}: #{inspect(Map.from_struct(greenhouse))}")
    end)
    
    greenhouses
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
    
    # Wait a bit and check database
    :timer.sleep(1000)
    
    case GreenhouseTycoon.Repo.get_by(GreenhouseTycoon.Greenhouse, greenhouse_id: greenhouse_id) do
      nil ->
        Logger.warning("Greenhouse #{greenhouse_id} not found in database")
      greenhouse ->
        Logger.info("Greenhouse #{greenhouse_id} found in database: #{inspect(Map.from_struct(greenhouse))}")
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
    
    # Step 3: Check database before creation
    Logger.info("Step 3: Checking database before creation")
    check_database()
    
    # Step 4: Create greenhouse
    Logger.info("Step 4: Creating greenhouse")
    result = create_test_greenhouse(greenhouse_id)
    
    # Step 5: Check database after creation
    Logger.info("Step 5: Checking database after creation")
    :timer.sleep(2000)  # Wait a bit longer
    check_database()
    list_database_entries()
    
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
    event = %EventV1{
      greenhouse_id: "test",
      name: "test",
      location: "50.0,4.0",
      city: "Brussels",
      country: "Belgium",
      target_temperature: nil,
      target_humidity: nil,
      target_light: nil,
      initialized_at: DateTime.utc_now(),
      version: 1
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
