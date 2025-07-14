defmodule SimulateCrops.GreenhouseCropSimulationCoordinator do
  @moduledoc """
  Coordinates crop simulation lifecycle for a specific greenhouse.

  Manages:
  - Starting and stopping crop simulation
  - Updating simulation parameters based on events
  - Coordinating between event listener and simulator
  """

  use GenServer
  require Logger

  def start_link(greenhouse_id) do
    GenServer.start_link(__MODULE__, greenhouse_id, 
      name: via_tuple(greenhouse_id, "simulation_coordinator"))
  end

  @impl true
  def init(greenhouse_id) do
    Logger.info("GreenhouseCropSimulationCoordinator started for greenhouse #{greenhouse_id}")

    state = %{
      greenhouse_id: greenhouse_id,
      simulation_active: false,
      crops: %{},
      environment: %{
        temperature: 20.0,
        humidity: 60.0,
        light_level: 50.0
      }
    }

    {:ok, state}
  end

  @impl true
  def handle_info({:crop_planted, event_data}, state) do
    Logger.info("Processing crop planted event for greenhouse #{state.greenhouse_id}")
    
    crop_id = event_data[:crop_id] || event_data["crop_id"]
    crop_type = event_data[:crop_type] || event_data["crop_type"]
    planted_at = event_data[:planted_at] || event_data["planted_at"] || DateTime.utc_now()
    
    crop_state = %{
      crop_id: crop_id,
      crop_type: crop_type,
      planted_at: planted_at,
      growth_stage: :seed,
      health: 100.0,
      growth_progress: 0.0,
      last_updated: DateTime.utc_now()
    }
    
    updated_state = put_in(state, [:crops, crop_id], crop_state)
    
    # Start simulation if not already active
    start_simulation_if_needed(updated_state)
    
    {:noreply, updated_state}
  end

  @impl true
  def handle_info({:crop_harvested, event_data}, state) do
    Logger.info("Processing crop harvested event for greenhouse #{state.greenhouse_id}")
    
    crop_id = event_data[:crop_id] || event_data["crop_id"]
    
    {_, updated_state} = pop_in(state, [:crops, crop_id])
    
    # Stop simulation if no crops remaining
    stop_simulation_if_no_crops(updated_state)
    
    {:noreply, updated_state}
  end

  @impl true
  def handle_info({:irrigation_applied, event_data}, state) do
    Logger.debug("Processing irrigation event for greenhouse #{state.greenhouse_id}")
    
    # Update crop health based on irrigation
    updated_crops = 
      state.crops
      |> Enum.map(fn {crop_id, crop_state} ->
        updated_crop = Map.update!(crop_state, :health, &min(&1 + 5.0, 100.0))
        {crop_id, updated_crop}
      end)
      |> Enum.into(%{})
    
    updated_state = %{state | crops: updated_crops}
    
    {:noreply, updated_state}
  end

  @impl true
  def handle_info({:fertilizer_applied, event_data}, state) do
    Logger.debug("Processing fertilizer event for greenhouse #{state.greenhouse_id}")
    
    # Update crop growth rate based on fertilization
    updated_crops = 
      state.crops
      |> Enum.map(fn {crop_id, crop_state} ->
        updated_crop = Map.update!(crop_state, :health, &min(&1 + 10.0, 100.0))
        {crop_id, updated_crop}
      end)
      |> Enum.into(%{})
    
    updated_state = %{state | crops: updated_crops}
    
    {:noreply, updated_state}
  end

  @impl true
  def handle_info({:environment_updated, event_data}, state) do
    Logger.debug("Processing environment update for greenhouse #{state.greenhouse_id}")
    
    environment_updates = %{
      temperature: event_data[:temperature] || event_data["temperature"] || state.environment.temperature,
      humidity: event_data[:humidity] || event_data["humidity"] || state.environment.humidity,
      light_level: event_data[:light_level] || event_data["light_level"] || state.environment.light_level
    }
    
    updated_state = %{state | environment: environment_updates}
    
    {:noreply, updated_state}
  end

  @impl true
  def handle_info(:start_simulation, state) do
    Logger.info("Starting crop simulation for greenhouse #{state.greenhouse_id}")
    
    # Notify simulator to start
    send_to_simulator(state.greenhouse_id, :start_simulation)
    
    updated_state = %{state | simulation_active: true}
    {:noreply, updated_state}
  end

  @impl true
  def handle_info(:stop_simulation, state) do
    Logger.info("Stopping crop simulation for greenhouse #{state.greenhouse_id}")
    
    # Notify simulator to stop
    send_to_simulator(state.greenhouse_id, :stop_simulation)
    
    updated_state = %{state | simulation_active: false}
    {:noreply, updated_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(message, state) do
    Logger.debug("Ignoring message: #{inspect(message)}")
    {:noreply, state}
  end

  defp start_simulation_if_needed(state) do
    if not state.simulation_active and map_size(state.crops) > 0 do
      send(self(), :start_simulation)
    end
  end

  defp stop_simulation_if_no_crops(state) do
    if state.simulation_active and map_size(state.crops) == 0 do
      send(self(), :stop_simulation)
    end
  end

  defp send_to_simulator(greenhouse_id, message) do
    case Registry.lookup(SimulateCrops.Registry, "#{greenhouse_id}_simulator") do
      [{pid, _}] ->
        send(pid, message)
      
      [] ->
        Logger.warning("No simulator found for greenhouse #{greenhouse_id}")
    end
  end

  defp via_tuple(greenhouse_id, process_type) do
    {:via, Registry, {SimulateCrops.Registry, "#{greenhouse_id}_#{process_type}"}}
  end
end
