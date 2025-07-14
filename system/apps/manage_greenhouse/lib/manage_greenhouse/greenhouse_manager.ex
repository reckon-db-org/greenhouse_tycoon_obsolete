defmodule ManageGreenhouse.GreenhouseManager do
  @moduledoc """
  Manages individual greenhouse instances and their simulators.
  
  This GenServer:
  - Listens for greenhouse lifecycle events
  - Starts/stops individual greenhouse processes
  - Coordinates with the simulator for each greenhouse
  - Maintains a registry of active greenhouses
  """
  
  use GenServer
  require Logger
  
  alias ManageGreenhouse.Events
  alias ManageGreenhouse.Commands
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(_opts) do
    Logger.info("GreenhouseManager: Starting greenhouse manager")
    
    # Subscribe to relevant events
    subscribe_to_events()
    
    initial_state = %{
      active_greenhouses: %{},
      greenhouse_simulators: %{}
    }
    
    {:ok, initial_state}
  end
  
  # Event handlers
  def handle_info({:greenhouse_initialized, %Events.GreenhouseInitialized{} = event}, state) do
    Logger.info("GreenhouseManager: Greenhouse initialized: #{event.greenhouse_id}")
    
    # Start a greenhouse process
    greenhouse_spec = {
      ManageGreenhouse.GreenhouseProcess,
      [
        greenhouse_id: event.greenhouse_id,
        name: event.name,
        location: event.location,
        config: extract_greenhouse_config(event)
      ]
    }
    
    case DynamicSupervisor.start_child(ManageGreenhouse.GreenhouseSupervisor, greenhouse_spec) do
      {:ok, pid} ->
        Logger.info("GreenhouseManager: Started greenhouse process for #{event.greenhouse_id}")
        
        new_state = %{
          state | 
          active_greenhouses: Map.put(state.active_greenhouses, event.greenhouse_id, pid)
        }
        
        {:noreply, new_state}
      
      {:error, reason} ->
        Logger.error("GreenhouseManager: Failed to start greenhouse process for #{event.greenhouse_id}: #{inspect(reason)}")
        {:noreply, state}
    end
  end
  
  def handle_info({:greenhouse_activated, %Events.GreenhouseActivated{} = event}, state) do
    Logger.info("GreenhouseManager: Greenhouse activated: #{event.greenhouse_id}")
    
    # Start simulation for the greenhouse
    start_simulation_for_greenhouse(event.greenhouse_id, state)
  end
  
  def handle_info({:greenhouse_deactivated, %Events.GreenhouseDeactivated{} = event}, state) do
    Logger.info("GreenhouseManager: Greenhouse deactivated: #{event.greenhouse_id}")
    
    # Stop simulation for the greenhouse
    stop_simulation_for_greenhouse(event.greenhouse_id, state)
  end
  
  def handle_info({:greenhouse_simulation_started, %Events.GreenhouseSimulationStarted{} = event}, state) do
    Logger.info("GreenhouseManager: Simulation started for greenhouse: #{event.greenhouse_id}")
    
    # Start the individual simulator for this greenhouse
    simulation_config = event.simulation_config || %{}
    
    case Simulator.start_simulation(event.greenhouse_id, simulation_config) do
      {:ok, simulator_state} ->
        Logger.info("GreenhouseManager: Started simulator for greenhouse #{event.greenhouse_id}")
        
        new_state = %{
          state | 
          greenhouse_simulators: Map.put(state.greenhouse_simulators, event.greenhouse_id, simulator_state)
        }
        
        {:noreply, new_state}
      
      {:error, reason} ->
        Logger.error("GreenhouseManager: Failed to start simulator for greenhouse #{event.greenhouse_id}: #{inspect(reason)}")
        {:noreply, state}
    end
  end
  
  def handle_info({:greenhouse_simulation_stopped, %Events.GreenhouseSimulationStopped{} = event}, state) do
    Logger.info("GreenhouseManager: Simulation stopped for greenhouse: #{event.greenhouse_id}")
    
    # Stop the individual simulator for this greenhouse
    case Simulator.stop_simulation(event.greenhouse_id) do
      :ok ->
        Logger.info("GreenhouseManager: Stopped simulator for greenhouse #{event.greenhouse_id}")
        
        new_state = %{
          state | 
          greenhouse_simulators: Map.delete(state.greenhouse_simulators, event.greenhouse_id)
        }
        
        {:noreply, new_state}
      
      {:error, reason} ->
        Logger.error("GreenhouseManager: Failed to stop simulator for greenhouse #{event.greenhouse_id}: #{inspect(reason)}")
        {:noreply, state}
    end
  end
  
  def handle_info({:greenhouse_retired, %Events.GreenhouseRetired{} = event}, state) do
    Logger.info("GreenhouseManager: Greenhouse retired: #{event.greenhouse_id}")
    
    # Stop both simulation and greenhouse process
    stop_simulation_for_greenhouse(event.greenhouse_id, state)
    stop_greenhouse_process(event.greenhouse_id, state)
  end
  
  # Public API
  def get_active_greenhouses do
    GenServer.call(__MODULE__, :get_active_greenhouses)
  end
  
  def get_greenhouse_simulators do
    GenServer.call(__MODULE__, :get_greenhouse_simulators)
  end
  
  def handle_call(:get_active_greenhouses, _from, state) do
    {:reply, state.active_greenhouses, state}
  end
  
  def handle_call(:get_greenhouse_simulators, _from, state) do
    {:reply, state.greenhouse_simulators, state}
  end
  
  # Private functions
  
  defp subscribe_to_events do
    # Subscribe to ManageGreenhouse events
    Phoenix.PubSub.subscribe(ManageGreenhouse.PubSub, "greenhouse_events")
    
    # In a real implementation, you would subscribe to the actual event streams
    # For now, we'll simulate event subscription
    Logger.debug("GreenhouseManager: Subscribed to greenhouse events")
  end
  
  defp extract_greenhouse_config(event) do
    %{
      coordinates: event.coordinates,
      capacity: event.capacity,
      greenhouse_type: event.greenhouse_type,
      city: event.city,
      country: event.country
    }
  end
  
  defp start_simulation_for_greenhouse(greenhouse_id, _state) do
    # Create a command to start simulation
    command = %Commands.StartGreenhouseSimulation{
      greenhouse_id: greenhouse_id,
      simulation_config: %{
        simulation_speed: 1.0,
        weather_integration: true,
        autonomous_mode: true
      },
      started_by: "system"
    }
    
    Logger.info("GreenhouseManager: Starting simulation for greenhouse #{greenhouse_id}")
    
    # In a real implementation, this would dispatch the command through Commanded
    # For now, we'll simulate the command dispatch
    simulate_command_dispatch(command)
  end
  
  defp stop_simulation_for_greenhouse(greenhouse_id, _state) do
    # Create a command to stop simulation
    command = %Commands.StopGreenhouseSimulation{
      greenhouse_id: greenhouse_id,
      stop_reason: "greenhouse_deactivated",
      stopped_by: "system"
    }
    
    Logger.info("GreenhouseManager: Stopping simulation for greenhouse #{greenhouse_id}")
    
    # In a real implementation, this would dispatch the command through Commanded
    # For now, we'll simulate the command dispatch
    simulate_command_dispatch(command)
  end
  
  defp stop_greenhouse_process(greenhouse_id, state) do
    case Map.get(state.active_greenhouses, greenhouse_id) do
      nil ->
        Logger.warning("GreenhouseManager: No active process found for greenhouse #{greenhouse_id}")
        {:noreply, state}
      
      pid ->
        Logger.info("GreenhouseManager: Stopping greenhouse process for #{greenhouse_id}")
        DynamicSupervisor.terminate_child(ManageGreenhouse.GreenhouseSupervisor, pid)
        
        new_state = %{
          state | 
          active_greenhouses: Map.delete(state.active_greenhouses, greenhouse_id)
        }
        
        {:noreply, new_state}
    end
  end
  
  defp simulate_command_dispatch(command) do
    # In a real implementation, this would use the Commanded application
    # For now, we'll just log and potentially trigger events
    Logger.debug("GreenhouseManager: Dispatching command: #{inspect(command)}")
    
    # Simulate event emission based on command type
    case command do
      %Commands.StartGreenhouseSimulation{} = cmd ->
        # Simulate GreenhouseSimulationStarted event
        event = %Events.GreenhouseSimulationStarted{
          greenhouse_id: cmd.greenhouse_id,
          simulation_config: cmd.simulation_config,
          initial_state: %{},
          started_by: cmd.started_by,
          simulation_started_at: DateTime.utc_now()
        }
        
        # In a real implementation, this would be handled by the event store
        send(self(), {:greenhouse_simulation_started, event})
        
      %Commands.StopGreenhouseSimulation{} = cmd ->
        # Simulate GreenhouseSimulationStopped event
        event = %Events.GreenhouseSimulationStopped{
          greenhouse_id: cmd.greenhouse_id,
          stop_reason: cmd.stop_reason,
          final_state: %{},
          simulation_duration: 0,
          stopped_by: cmd.stopped_by,
          simulation_stopped_at: DateTime.utc_now()
        }
        
        # In a real implementation, this would be handled by the event store
        send(self(), {:greenhouse_simulation_stopped, event})
        
      _ ->
        Logger.debug("GreenhouseManager: Command type not handled in simulation")
    end
  end
end
