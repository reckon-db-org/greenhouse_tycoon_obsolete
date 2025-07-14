defmodule SimulateAttrition.GreenhouseSupplyEventListener do
  @moduledoc """
  Event listener for supply-related events from a specific greenhouse.

  Listens for:
  - SupplyAdded events to initialize simulation state
  - SupplyConsumed events to track usage patterns
  - Equipment operation events to simulate consumption
  - Environmental change events to affect quality degradation
  - Supply inspection events to track quality
  """

  use GenServer
  require Logger

  def start_link(greenhouse_id) do
    GenServer.start_link(__MODULE__, greenhouse_id, 
      name: via_tuple(greenhouse_id, "event_listener"))
  end

  @impl true
  def init(greenhouse_id) do
    # Subscribe to supply events for this greenhouse
    Phoenix.PubSub.subscribe(SimulateAttrition.PubSub, "greenhouse:#{greenhouse_id}:supplies")
    Phoenix.PubSub.subscribe(SimulateAttrition.PubSub, "greenhouse:#{greenhouse_id}:equipment")
    Phoenix.PubSub.subscribe(SimulateAttrition.PubSub, "greenhouse:#{greenhouse_id}:environment")
    
    Logger.info("GreenhouseSupplyEventListener started for greenhouse #{greenhouse_id}")

    {:ok, %{greenhouse_id: greenhouse_id}}
  end

  @impl true
  def handle_info({:supply_added, event_data}, state) do
    Logger.debug("Supply added event received: #{inspect(event_data)}")
    
    # Notify the simulation coordinator
    send_to_coordinator(state.greenhouse_id, {:supply_added, event_data})
    
    {:noreply, state}
  end

  @impl true
  def handle_info({:supply_consumed, event_data}, state) do
    Logger.debug("Supply consumed event received: #{inspect(event_data)}")
    
    # Notify the simulation coordinator
    send_to_coordinator(state.greenhouse_id, {:supply_consumed, event_data})
    
    {:noreply, state}
  end

  @impl true
  def handle_info({:supply_replenished, event_data}, state) do
    Logger.debug("Supply replenished event received: #{inspect(event_data)}")
    
    # Notify the simulation coordinator
    send_to_coordinator(state.greenhouse_id, {:supply_replenished, event_data})
    
    {:noreply, state}
  end

  @impl true
  def handle_info({:equipment_activated, event_data}, state) do
    Logger.debug("Equipment activated event received: #{inspect(event_data)}")
    
    # Notify the simulation coordinator about potential supply consumption
    send_to_coordinator(state.greenhouse_id, {:equipment_activated, event_data})
    
    {:noreply, state}
  end

  @impl true
  def handle_info({:equipment_deactivated, event_data}, state) do
    Logger.debug("Equipment deactivated event received: #{inspect(event_data)}")
    
    # Notify the simulation coordinator
    send_to_coordinator(state.greenhouse_id, {:equipment_deactivated, event_data})
    
    {:noreply, state}
  end

  @impl true
  def handle_info({:environment_updated, event_data}, state) do
    Logger.debug("Environment updated event received: #{inspect(event_data)}")
    
    # Notify the simulation coordinator about environmental changes
    send_to_coordinator(state.greenhouse_id, {:environment_updated, event_data})
    
    {:noreply, state}
  end

  @impl true
  def handle_info({:supply_inspection_scheduled, event_data}, state) do
    Logger.debug("Supply inspection scheduled event received: #{inspect(event_data)}")
    
    # Notify the simulation coordinator
    send_to_coordinator(state.greenhouse_id, {:supply_inspection_scheduled, event_data})
    
    {:noreply, state}
  end

  @impl true
  def handle_info({:supply_inspection_completed, event_data}, state) do
    Logger.debug("Supply inspection completed event received: #{inspect(event_data)}")
    
    # Notify the simulation coordinator
    send_to_coordinator(state.greenhouse_id, {:supply_inspection_completed, event_data})
    
    {:noreply, state}
  end

  @impl true
  def handle_info({:supply_discarded, event_data}, state) do
    Logger.debug("Supply discarded event received: #{inspect(event_data)}")
    
    # Notify the simulation coordinator
    send_to_coordinator(state.greenhouse_id, {:supply_discarded, event_data})
    
    {:noreply, state}
  end

  @impl true
  def handle_info(event, state) do
    Logger.debug("Ignoring event: #{inspect(event)}")
    {:noreply, state}
  end

  defp send_to_coordinator(greenhouse_id, message) do
    case Registry.lookup(SimulateAttrition.Registry, "#{greenhouse_id}_simulation_coordinator") do
      [{pid, _}] ->
        send(pid, message)
      
      [] ->
        Logger.warning("No simulation coordinator found for greenhouse #{greenhouse_id}")
    end
  end

  defp via_tuple(greenhouse_id, process_type) do
    {:via, Registry, {SimulateAttrition.Registry, "#{greenhouse_id}_#{process_type}"}}
  end
end
