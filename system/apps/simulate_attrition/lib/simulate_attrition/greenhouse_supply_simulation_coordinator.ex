defmodule SimulateAttrition.GreenhouseSupplySimulationCoordinator do
  @moduledoc """
  Coordinates supply attrition simulation lifecycle for a specific greenhouse.

  Manages:
  - Starting and stopping supply simulation
  - Updating simulation parameters based on events
  - Coordinating between event listener and simulator
  - Tracking supply levels and consumption patterns
  """

  use GenServer
  require Logger

  def start_link(greenhouse_id) do
    GenServer.start_link(__MODULE__, greenhouse_id, 
      name: via_tuple(greenhouse_id, "simulation_coordinator"))
  end

  @impl true
  def init(greenhouse_id) do
    Logger.info("GreenhouseSupplySimulationCoordinator started for greenhouse #{greenhouse_id}")

    state = %{
      greenhouse_id: greenhouse_id,
      simulation_active: false,
      supplies: %{},
      equipment_states: %{},
      environment: %{
        temperature: 20.0,
        humidity: 60.0,
        light_level: 50.0
      },
      consumption_patterns: %{},
      last_attrition_check: DateTime.utc_now()
    }

    {:ok, state}
  end

  @impl true
  def handle_info({:supply_added, event_data}, state) do
    Logger.info("Processing supply added event for greenhouse #{state.greenhouse_id}")
    
    supply_type = event_data[:supply_type] || event_data["supply_type"]
    quantity = event_data[:quantity] || event_data["quantity"] || 0
    expiration_date = event_data[:expiration_date] || event_data["expiration_date"]
    batch_number = event_data[:batch_number] || event_data["batch_number"]
    
    supply_state = %{
      supply_type: supply_type,
      current_quantity: quantity,
      original_quantity: quantity,
      expiration_date: expiration_date,
      batch_number: batch_number,
      quality_percentage: 100.0,
      last_updated: DateTime.utc_now(),
      consumption_rate: 0.0,
      storage_conditions: %{
        temperature: state.environment.temperature,
        humidity: state.environment.humidity
      }
    }
    
    updated_state = put_in(state, [:supplies, supply_type], supply_state)
    
    # Start simulation if not already active and we have supplies
    start_simulation_if_needed(updated_state)
    
    {:noreply, updated_state}
  end

  @impl true
  def handle_info({:supply_consumed, event_data}, state) do
    Logger.info("Processing supply consumed event for greenhouse #{state.greenhouse_id}")
    
    supply_type = event_data[:supply_type] || event_data["supply_type"]
    quantity = event_data[:quantity] || event_data["quantity"] || 0
    
    updated_state = case Map.get(state.supplies, supply_type) do
      nil ->
        Logger.warning("Supply #{supply_type} not found in simulation state")
        state
      
      supply_state ->
        new_quantity = max(0, supply_state.current_quantity - quantity)
        updated_supply = %{supply_state | 
          current_quantity: new_quantity,
          last_updated: DateTime.utc_now()
        }
        
        # Update consumption pattern
        updated_patterns = update_consumption_pattern(state.consumption_patterns, supply_type, quantity)
        
        %{state | 
          supplies: Map.put(state.supplies, supply_type, updated_supply),
          consumption_patterns: updated_patterns
        }
    end
    
    {:noreply, updated_state}
  end

  @impl true
  def handle_info({:supply_replenished, event_data}, state) do
    Logger.info("Processing supply replenished event for greenhouse #{state.greenhouse_id}")
    
    supply_type = event_data[:supply_type] || event_data["supply_type"]
    quantity = event_data[:quantity] || event_data["quantity"] || 0
    
    updated_state = case Map.get(state.supplies, supply_type) do
      nil ->
        # Create new supply entry if not exists
        supply_state = %{
          supply_type: supply_type,
          current_quantity: quantity,
          original_quantity: quantity,
          expiration_date: event_data[:expiration_date] || event_data["expiration_date"],
          batch_number: event_data[:batch_number] || event_data["batch_number"],
          quality_percentage: 100.0,
          last_updated: DateTime.utc_now(),
          consumption_rate: 0.0,
          storage_conditions: %{
            temperature: state.environment.temperature,
            humidity: state.environment.humidity
          }
        }
        
        put_in(state, [:supplies, supply_type], supply_state)
      
      supply_state ->
        updated_supply = %{supply_state | 
          current_quantity: supply_state.current_quantity + quantity,
          last_updated: DateTime.utc_now()
        }
        
        %{state | supplies: Map.put(state.supplies, supply_type, updated_supply)}
    end
    
    # Start simulation if not already active
    start_simulation_if_needed(updated_state)
    
    {:noreply, updated_state}
  end

  @impl true
  def handle_info({:equipment_activated, event_data}, state) do
    Logger.debug("Processing equipment activated event for greenhouse #{state.greenhouse_id}")
    
    equipment_id = event_data[:equipment_id] || event_data["equipment_id"]
    equipment_type = event_data[:equipment_type] || event_data["equipment_type"]
    
    equipment_state = %{
      equipment_id: equipment_id,
      equipment_type: equipment_type,
      activated_at: DateTime.utc_now(),
      status: :active
    }
    
    updated_state = put_in(state, [:equipment_states, equipment_id], equipment_state)
    
    # Notify simulator about equipment activation for consumption calculation
    send_to_simulator(state.greenhouse_id, {:equipment_activated, event_data})
    
    {:noreply, updated_state}
  end

  @impl true
  def handle_info({:equipment_deactivated, event_data}, state) do
    Logger.debug("Processing equipment deactivated event for greenhouse #{state.greenhouse_id}")
    
    equipment_id = event_data[:equipment_id] || event_data["equipment_id"]
    
    updated_state = case Map.get(state.equipment_states, equipment_id) do
      nil -> state
      equipment_state ->
        updated_equipment = %{equipment_state | 
          status: :inactive,
          deactivated_at: DateTime.utc_now()
        }
        %{state | equipment_states: Map.put(state.equipment_states, equipment_id, updated_equipment)}
    end
    
    # Notify simulator about equipment deactivation
    send_to_simulator(state.greenhouse_id, {:equipment_deactivated, event_data})
    
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
    
    # Notify simulator about environmental changes
    send_to_simulator(state.greenhouse_id, {:environment_updated, environment_updates})
    
    {:noreply, updated_state}
  end

  @impl true
  def handle_info(:start_simulation, state) do
    Logger.info("Starting supply attrition simulation for greenhouse #{state.greenhouse_id}")
    
    # Notify simulator to start
    send_to_simulator(state.greenhouse_id, :start_simulation)
    
    updated_state = %{state | simulation_active: true}
    {:noreply, updated_state}
  end

  @impl true
  def handle_info(:stop_simulation, state) do
    Logger.info("Stopping supply attrition simulation for greenhouse #{state.greenhouse_id}")
    
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
    if not state.simulation_active and map_size(state.supplies) > 0 do
      send(self(), :start_simulation)
    end
  end

  defp stop_simulation_if_no_supplies(state) do
    if state.simulation_active and map_size(state.supplies) == 0 do
      send(self(), :stop_simulation)
    end
  end

  defp update_consumption_pattern(patterns, supply_type, quantity) do
    current_pattern = Map.get(patterns, supply_type, %{
      total_consumed: 0,
      consumption_events: 0,
      average_rate: 0.0,
      last_consumption: DateTime.utc_now()
    })
    
    new_total = current_pattern.total_consumed + quantity
    new_events = current_pattern.consumption_events + 1
    new_average = new_total / new_events
    
    updated_pattern = %{current_pattern |
      total_consumed: new_total,
      consumption_events: new_events,
      average_rate: new_average,
      last_consumption: DateTime.utc_now()
    }
    
    Map.put(patterns, supply_type, updated_pattern)
  end

  defp send_to_simulator(greenhouse_id, message) do
    case Registry.lookup(SimulateAttrition.Registry, "#{greenhouse_id}_simulator") do
      [{pid, _}] ->
        send(pid, message)
      
      [] ->
        Logger.warning("No simulator found for greenhouse #{greenhouse_id}")
    end
  end

  defp via_tuple(greenhouse_id, process_type) do
    {:via, Registry, {SimulateAttrition.Registry, "#{greenhouse_id}_#{process_type}"}}
  end
end
