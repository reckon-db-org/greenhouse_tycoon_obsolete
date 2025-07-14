defmodule SimulateCrops.GreenhouseCropEventListener do
  @moduledoc """
  Event listener for crop-related events from a specific greenhouse.

  Listens for:
  - CropPlanted events to initialize simulation state
  - CropHarvested events to update simulation
  - Environmental change events to adjust growth rates
  - Irrigation/fertilization events to affect crop health
  """

  use GenServer
  require Logger

  def start_link(greenhouse_id) do
    GenServer.start_link(__MODULE__, greenhouse_id, 
      name: via_tuple(greenhouse_id, "event_listener"))
  end

  @impl true
  def init(greenhouse_id) do
    # Subscribe to crop events for this greenhouse
    Phoenix.PubSub.subscribe(SimulateCrops.PubSub, "greenhouse:#{greenhouse_id}:crops")
    Phoenix.PubSub.subscribe(SimulateCrops.PubSub, "greenhouse:#{greenhouse_id}:environment")
    
    Logger.info("GreenhouseCropEventListener started for greenhouse #{greenhouse_id}")

    {:ok, %{greenhouse_id: greenhouse_id}}
  end

  @impl true
  def handle_info({:crop_planted, event_data}, state) do
    Logger.debug("Crop planted event received: #{inspect(event_data)}")
    
    # Notify the simulation coordinator
    send_to_coordinator(state.greenhouse_id, {:crop_planted, event_data})
    
    {:noreply, state}
  end

  @impl true
  def handle_info({:crop_harvested, event_data}, state) do
    Logger.debug("Crop harvested event received: #{inspect(event_data)}")
    
    # Notify the simulation coordinator
    send_to_coordinator(state.greenhouse_id, {:crop_harvested, event_data})
    
    {:noreply, state}
  end

  @impl true
  def handle_info({:irrigation_applied, event_data}, state) do
    Logger.debug("Irrigation applied event received: #{inspect(event_data)}")
    
    # Notify the simulation coordinator
    send_to_coordinator(state.greenhouse_id, {:irrigation_applied, event_data})
    
    {:noreply, state}
  end

  @impl true
  def handle_info({:fertilizer_applied, event_data}, state) do
    Logger.debug("Fertilizer applied event received: #{inspect(event_data)}")
    
    # Notify the simulation coordinator
    send_to_coordinator(state.greenhouse_id, {:fertilizer_applied, event_data})
    
    {:noreply, state}
  end

  @impl true
  def handle_info({:environment_updated, event_data}, state) do
    Logger.debug("Environment updated event received: #{inspect(event_data)}")
    
    # Notify the simulation coordinator
    send_to_coordinator(state.greenhouse_id, {:environment_updated, event_data})
    
    {:noreply, state}
  end

  @impl true
  def handle_info(event, state) do
    Logger.debug("Ignoring event: #{inspect(event)}")
    {:noreply, state}
  end

  defp send_to_coordinator(greenhouse_id, message) do
    case Registry.lookup(SimulateCrops.Registry, "#{greenhouse_id}_simulation_coordinator") do
      [{pid, _}] ->
        send(pid, message)
      
      [] ->
        Logger.warning("No simulation coordinator found for greenhouse #{greenhouse_id}")
    end
  end

  defp via_tuple(greenhouse_id, process_type) do
    {:via, Registry, {SimulateCrops.Registry, "#{greenhouse_id}_#{process_type}"}}
  end
end
