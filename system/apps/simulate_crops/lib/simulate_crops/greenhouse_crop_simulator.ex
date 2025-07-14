defmodule SimulateCrops.GreenhouseCropSimulator do
  @moduledoc """
  Individual greenhouse crop simulator.
  
  Each greenhouse gets its own instance of this GenServer to simulate
  crop growth, health, and lifecycle events for all crops in that greenhouse.
  """
  
  use GenServer
  require Logger
  
  alias SimulateCrops.{CropGrowthEngine, Events}
  
  # Growth simulation interval - runs every 5 minutes
  @growth_tick_interval :timer.minutes(5)
  
  def start_link(args) do
    greenhouse_id = Keyword.get(args, :greenhouse_id)
    GenServer.start_link(__MODULE__, args, name: via_tuple(greenhouse_id))
  end
  
  def init(args) do
    greenhouse_id = Keyword.get(args, :greenhouse_id)
    config = Keyword.get(args, :config, %{})
    
    Logger.info("GreenhouseCropSimulator: Starting for greenhouse #{greenhouse_id}")
    
    # Schedule the first growth tick
    schedule_growth_tick()
    
    {:ok, %{
      greenhouse_id: greenhouse_id,
      config: config,
      crops: %{},
      environmental_conditions: %{
        temperature: 22.0,
        humidity: 65.0,
        light: 600.0,
        last_updated: DateTime.utc_now()
      }
    }}
  end
  
  # Public API
  
  def start_crop_simulation(pid, crop_id, crop_config) do
    GenServer.call(pid, {:start_crop, crop_id, crop_config})
  end
  
  def stop_crop_simulation(pid, crop_id) do
    GenServer.call(pid, {:stop_crop, crop_id})
  end
  
  def update_environmental_conditions(pid, conditions) do
    GenServer.cast(pid, {:update_environment, conditions})
  end
  
  def get_crop_status(pid, crop_id) do
    GenServer.call(pid, {:get_crop_status, crop_id})
  end
  
  def get_all_crops(pid) do
    GenServer.call(pid, :get_all_crops)
  end
  
  # GenServer callbacks
  
  def handle_call({:start_crop, crop_id, crop_config}, _from, state) do
    Logger.info("GreenhouseCropSimulator: Starting simulation for crop #{crop_id}")
    
    # Initialize crop state
    crop_state = %{
      crop_id: crop_id,
      crop_type: crop_config.crop_type,
      planted_at: crop_config.planted_at || DateTime.utc_now(),
      expected_harvest_date: crop_config.expected_harvest_date,
      growth_stage: :germination,
      growth_progress: 0.0,
      health_status: :healthy,
      last_growth_update: DateTime.utc_now(),
      environmental_factors: %{}
    }
    
    new_state = %{state | crops: Map.put(state.crops, crop_id, crop_state)}
    
    # Emit simulation started event
    emit_crop_simulation_event(:crop_simulation_started, crop_state, state)
    
    {:reply, {:ok, crop_state}, new_state}
  end
  
  def handle_call({:stop_crop, crop_id}, _from, state) do
    Logger.info("GreenhouseCropSimulator: Stopping simulation for crop #{crop_id}")
    
    case Map.get(state.crops, crop_id) do
      nil ->
        {:reply, {:error, :crop_not_found}, state}
        
      crop_state ->
        # Emit simulation stopped event
        emit_crop_simulation_event(:crop_simulation_stopped, crop_state, state)
        
        new_state = %{state | crops: Map.delete(state.crops, crop_id)}
        {:reply, :ok, new_state}
    end
  end
  
  def handle_call({:get_crop_status, crop_id}, _from, state) do
    crop_status = Map.get(state.crops, crop_id)
    {:reply, crop_status, state}
  end
  
  def handle_call(:get_all_crops, _from, state) do
    {:reply, state.crops, state}
  end
  
  def handle_cast({:update_environment, conditions}, state) do
    Logger.debug("GreenhouseCropSimulator: Updating environmental conditions")
    
    updated_conditions = Map.merge(state.environmental_conditions, conditions)
    updated_conditions = Map.put(updated_conditions, :last_updated, DateTime.utc_now())
    
    new_state = %{state | environmental_conditions: updated_conditions}
    
    # Trigger immediate growth calculation for all crops
    new_state = update_all_crops_with_environment(new_state)
    
    {:noreply, new_state}
  end
  
  # Handle periodic growth ticks
  def handle_info(:growth_tick, state) do
    Logger.debug("GreenhouseCropSimulator: Processing growth tick for #{map_size(state.crops)} crops")
    
    new_state = simulate_crop_growth(state)
    
    # Schedule next growth tick
    schedule_growth_tick()
    
    {:noreply, new_state}
  end
  
  # Private functions
  
  defp simulate_crop_growth(state) do
    updated_crops = state.crops
    |> Enum.map(fn {crop_id, crop_state} ->
      updated_crop = CropGrowthEngine.calculate_growth(crop_state, state.environmental_conditions)
      
      # Check if growth stage changed or significant progress made
      if should_emit_growth_event?(crop_state, updated_crop) do
        emit_crop_simulation_event(:crop_growth_progressed, updated_crop, state)
      end
      
      # Check if crop is ready for harvest
      if CropGrowthEngine.ready_for_harvest?(updated_crop) do
        emit_crop_simulation_event(:crop_ready_for_harvest, updated_crop, state)
      end
      
      {crop_id, updated_crop}
    end)
    |> Enum.into(%{})
    
    %{state | crops: updated_crops}
  end
  
  defp update_all_crops_with_environment(state) do
    updated_crops = state.crops
    |> Enum.map(fn {crop_id, crop_state} ->
      updated_crop = CropGrowthEngine.apply_environmental_effects(crop_state, state.environmental_conditions)
      {crop_id, updated_crop}
    end)
    |> Enum.into(%{})
    
    %{state | crops: updated_crops}
  end
  
  defp should_emit_growth_event?(old_crop, new_crop) do
    # Emit event if growth stage changed or progress increased significantly
    old_crop.growth_stage != new_crop.growth_stage or
    (new_crop.growth_progress - old_crop.growth_progress) >= 10.0
  end
  
  defp emit_crop_simulation_event(event_type, crop_state, simulator_state) do
    event_data = case event_type do
      :crop_simulation_started ->
        %Events.CropSimulationStarted{
          greenhouse_id: simulator_state.greenhouse_id,
          crop_id: crop_state.crop_id,
          crop_type: crop_state.crop_type,
          started_at: DateTime.utc_now()
        }
        
      :crop_growth_progressed ->
        %Events.CropGrowthProgressed{
          greenhouse_id: simulator_state.greenhouse_id,
          crop_id: crop_state.crop_id,
          growth_stage: crop_state.growth_stage,
          growth_progress: crop_state.growth_progress,
          health_status: crop_state.health_status,
          progressed_at: DateTime.utc_now()
        }
        
      :crop_ready_for_harvest ->
        %Events.CropReadyForHarvest{
          greenhouse_id: simulator_state.greenhouse_id,
          crop_id: crop_state.crop_id,
          crop_type: crop_state.crop_type,
          estimated_yield: CropGrowthEngine.estimate_yield(crop_state),
          ready_at: DateTime.utc_now()
        }
        
      :crop_simulation_stopped ->
        %Events.CropSimulationStopped{
          greenhouse_id: simulator_state.greenhouse_id,
          crop_id: crop_state.crop_id,
          final_state: crop_state,
          stopped_at: DateTime.utc_now()
        }
    end
    
    # Publish event via PubSub
    Phoenix.PubSub.broadcast(SimulateCrops.PubSub, "crop_simulation_events", {event_type, event_data})
    
    Logger.info("GreenhouseCropSimulator: Emitted #{event_type} for crop #{crop_state.crop_id}")
  end
  
  defp schedule_growth_tick do
    Process.send_after(self(), :growth_tick, @growth_tick_interval)
  end
  
  defp via_tuple(greenhouse_id) do
    {:via, Registry, {SimulateCrops.Registry, {:greenhouse_simulator, greenhouse_id}}}
  end
end
