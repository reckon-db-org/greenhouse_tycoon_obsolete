defmodule SimulateCrops.EventListener do
  @moduledoc """
  Event listener that subscribes to crop-related events and 
  triggers simulation processes.
  """
  
  use GenServer
  require Logger
  
  alias SimulateCrops.SimulationCoordinator
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(_opts) do
    Logger.info("SimulateCrops.EventListener: Starting event listener")
    
    # Subscribe to relevant event streams
    subscribe_to_events()
    
    {:ok, %{}}
  end
  
  # Handle crop planted events
  def handle_info({:crop_planted, event}, state) do
    Logger.info("SimulateCrops.EventListener: Received CropPlanted event for #{event.crop_id}")
    
    # Start simulation for this crop
    SimulationCoordinator.start_crop_simulation(event.greenhouse_id, event.crop_id, %{
      crop_type: event.crop_type,
      planted_at: event.planted_at,
      expected_harvest_date: event.expected_harvest_date
    })
    
    {:noreply, state}
  end
  
  # Handle crop harvested events
  def handle_info({:crop_harvested, event}, state) do
    Logger.info("SimulateCrops.EventListener: Received CropHarvested event for #{event.crop_id}")
    
    # Stop simulation for this crop
    SimulationCoordinator.stop_crop_simulation(event.greenhouse_id, event.crop_id)
    
    {:noreply, state}
  end
  
  # Handle greenhouse initialized events
  def handle_info({:greenhouse_initialized, event}, state) do
    Logger.info("SimulateCrops.EventListener: Received GreenhouseInitialized event for #{event.greenhouse_id}")
    
    # Initialize crop simulation management for this greenhouse
    SimulationCoordinator.initialize_greenhouse_simulation(event.greenhouse_id, %{
      location: event.location,
      greenhouse_type: event.greenhouse_type,
      capacity: event.capacity
    })
    
    {:noreply, state}
  end
  
  # Handle greenhouse deactivated events
  def handle_info({:greenhouse_deactivated, event}, state) do
    Logger.info("SimulateCrops.EventListener: Received GreenhouseDeactivated event for #{event.greenhouse_id}")
    
    # Stop all crop simulations for this greenhouse
    SimulationCoordinator.stop_greenhouse_simulation(event.greenhouse_id)
    
    {:noreply, state}
  end
  
  # Handle environmental events that affect crop growth
  def handle_info({:temperature_measured, event}, state) do
    Logger.debug("SimulateCrops.EventListener: Received TemperatureMeasured event for #{event.greenhouse_id}")
    
    # Update environmental conditions for crop simulations
    SimulationCoordinator.update_environmental_conditions(event.greenhouse_id, %{
      temperature: event.temperature,
      measured_at: event.measured_at
    })
    
    {:noreply, state}
  end
  
  def handle_info({:humidity_measured, event}, state) do
    Logger.debug("SimulateCrops.EventListener: Received HumidityMeasured event for #{event.greenhouse_id}")
    
    SimulationCoordinator.update_environmental_conditions(event.greenhouse_id, %{
      humidity: event.humidity,
      measured_at: event.measured_at
    })
    
    {:noreply, state}
  end
  
  def handle_info({:light_measured, event}, state) do
    Logger.debug("SimulateCrops.EventListener: Received LightMeasured event for #{event.greenhouse_id}")
    
    SimulationCoordinator.update_environmental_conditions(event.greenhouse_id, %{
      light: event.light,
      measured_at: event.measured_at
    })
    
    {:noreply, state}
  end
  
  # Catch-all for unhandled events
  def handle_info(event, state) do
    Logger.debug("SimulateCrops.EventListener: Unhandled event: #{inspect(event)}")
    {:noreply, state}
  end
  
  # Private functions
  
  defp subscribe_to_events do
    # In a real implementation, these would be event stream subscriptions
    # For now, we'll use PubSub topics to simulate event streams
    
    # Subscribe to crop management events
    Phoenix.PubSub.subscribe(SimulateCrops.PubSub, "crop_events")
    
    # Subscribe to greenhouse lifecycle events
    Phoenix.PubSub.subscribe(SimulateCrops.PubSub, "greenhouse_events")
    
    # Subscribe to environmental events
    Phoenix.PubSub.subscribe(SimulateCrops.PubSub, "environmental_events")
    
    Logger.info("SimulateCrops.EventListener: Subscribed to event streams")
  end
end
