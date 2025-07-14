defmodule SimulateAttrition.GreenhouseSupplySimulator do
  @moduledoc """
  Individual greenhouse supply attrition simulator.
  
  Each greenhouse gets its own instance of this GenServer to simulate
  supply attrition, consumption, and lifecycle events for all supplies in that greenhouse.
  """
  
  use GenServer
  require Logger

  alias SimulateAttrition.Events

  # Simulation intervals
  @attrition_tick_interval :timer.minutes(15)

  def start_link(args) do
    greenhouse_id = Keyword.get(args, :greenhouse_id)
    GenServer.start_link(__MODULE__, args, name: via_tuple(greenhouse_id))
  end
  
  def init(args) do
    greenhouse_id = Keyword.get(args, :greenhouse_id)
    config = Keyword.get(args, :config, %{})
    
    Logger.info("GreenhouseSupplySimulator: Starting for greenhouse #{greenhouse_id}")
    
    # Schedule the first attrition tick
    schedule_attrition_tick()
    
    {:ok, %{
      greenhouse_id: greenhouse_id,
      config: config,
      supplies: %{},
      environmental_conditions: %{
        temperature: 22.0,
        humidity: 65.0,
        last_updated: DateTime.utc_now()
      }
    }}
  end

  # GenServer callbacks
  
  @impl true
  def handle_cast({:environment_updated, conditions}, state) do
    Logger.debug("GreenhouseSupplySimulator: Updating environmental conditions")
    
    updated_conditions = Map.merge(state.environmental_conditions, conditions)
    updated_conditions = Map.put(updated_conditions, :last_updated, DateTime.utc_now())
    
    new_state = %{state | environmental_conditions: updated_conditions}
    
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:equipment_activated, event_data}, state) do
    Logger.debug("GreenhouseSupplySimulator: Equipment activated")
    # Handle equipment-specific supply consumption logic
    {:noreply, state}
  end

  @impl true
  def handle_cast({:equipment_deactivated, event_data}, state) do
    Logger.debug("GreenhouseSupplySimulator: Equipment deactivated")
    # Handle equipment-specific supply consumption logic
    {:noreply, state}
  end

  @impl true
  def handle_info(:attrition_tick, state) do
    Logger.debug("GreenhouseSupplySimulator: Processing attrition tick for supplies")
    
    new_state = simulate_supply_attrition(state)
    schedule_attrition_tick()
    {:noreply, new_state}
  end

  # Private functions
  
  defp simulate_supply_attrition(state) do
    # Simulate supply attrition based on current state
    # Loop through supplies, calculate attrition, and emit events if needed
    state  # For now, we simply return the state without modification
  end

  defp schedule_attrition_tick do
    Process.send_after(self(), :attrition_tick, @attrition_tick_interval)
  end

  defp via_tuple(greenhouse_id) do
    {:via, Registry, {SimulateAttrition.Registry, {:greenhouse_simulator, greenhouse_id}}}
  end
end
