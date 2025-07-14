defmodule ManageGreenhouse do
  @moduledoc """
  Greenhouse Management System.
  
  This module provides the main API for managing greenhouse lifecycle operations:
  - Initializing new greenhouses
  - Activating/deactivating greenhouses
  - Starting/stopping simulations
  - Managing greenhouse configurations
  
  Each greenhouse gets its own process and simulator instance for
  independent operation and simulation.
  """

  alias ManageGreenhouse.{Commands, Events}
  alias ManageGreenhouse.GreenhouseManager
  require Logger

  @doc """
  Initializes a new greenhouse.
  """
  def initialize_greenhouse(greenhouse_id, name, location, opts \\ []) do
    command = %Commands.InitializeGreenhouse{
      greenhouse_id: greenhouse_id,
      name: name,
      location: location,
      city: Keyword.get(opts, :city),
      country: Keyword.get(opts, :country),
      coordinates: Keyword.get(opts, :coordinates),
      capacity: Keyword.get(opts, :capacity),
      greenhouse_type: Keyword.get(opts, :greenhouse_type),
      initialized_by: Keyword.get(opts, :initialized_by)
    }
    
    Logger.info("Initializing greenhouse: #{greenhouse_id}")
    
    # In a real implementation, this would dispatch through Commanded
    # For now, we'll simulate the command dispatch
    simulate_command_dispatch(command)
  end

  @doc """
  Activates a greenhouse.
  """
  def activate_greenhouse(greenhouse_id, opts \\ []) do
    command = %Commands.ActivateGreenhouse{
      greenhouse_id: greenhouse_id,
      activated_by: Keyword.get(opts, :activated_by),
      activation_reason: Keyword.get(opts, :activation_reason),
      target_conditions: Keyword.get(opts, :target_conditions)
    }
    
    Logger.info("Activating greenhouse: #{greenhouse_id}")
    simulate_command_dispatch(command)
  end

  @doc """
  Deactivates a greenhouse.
  """
  def deactivate_greenhouse(greenhouse_id, opts \\ []) do
    command = %Commands.DeactivateGreenhouse{
      greenhouse_id: greenhouse_id,
      deactivated_by: Keyword.get(opts, :deactivated_by),
      deactivation_reason: Keyword.get(opts, :deactivation_reason)
    }
    
    Logger.info("Deactivating greenhouse: #{greenhouse_id}")
    simulate_command_dispatch(command)
  end

  @doc """
  Starts simulation for a greenhouse.
  """
  def start_simulation(greenhouse_id, opts \\ []) do
    command = %Commands.StartGreenhouseSimulation{
      greenhouse_id: greenhouse_id,
      simulation_config: Keyword.get(opts, :simulation_config, %{}),
      initial_state: Keyword.get(opts, :initial_state, %{}),
      started_by: Keyword.get(opts, :started_by)
    }
    
    Logger.info("Starting simulation for greenhouse: #{greenhouse_id}")
    simulate_command_dispatch(command)
  end

  @doc """
  Stops simulation for a greenhouse.
  """
  def stop_simulation(greenhouse_id, opts \\ []) do
    command = %Commands.StopGreenhouseSimulation{
      greenhouse_id: greenhouse_id,
      stop_reason: Keyword.get(opts, :stop_reason, "manual_stop"),
      stopped_by: Keyword.get(opts, :stopped_by)
    }
    
    Logger.info("Stopping simulation for greenhouse: #{greenhouse_id}")
    simulate_command_dispatch(command)
  end

  @doc """
  Gets the list of active greenhouses.
  """
  def get_active_greenhouses do
    GreenhouseManager.get_active_greenhouses()
  end

  @doc """
  Gets the list of greenhouse simulators.
  """
  def get_greenhouse_simulators do
    GreenhouseManager.get_greenhouse_simulators()
  end

  # Private helper functions
  
  defp simulate_command_dispatch(command) do
    # In a real implementation, this would use the Commanded application
    # For now, we'll simulate event emission
    Logger.debug("ManageGreenhouse: Dispatching command: #{inspect(command)}")
    
    case command do
      %Commands.InitializeGreenhouse{} = cmd ->
        event = %Events.GreenhouseInitialized{
          greenhouse_id: cmd.greenhouse_id,
          name: cmd.name,
          location: cmd.location,
          city: cmd.city,
          country: cmd.country,
          coordinates: cmd.coordinates,
          capacity: cmd.capacity,
          greenhouse_type: cmd.greenhouse_type,
          initialized_by: cmd.initialized_by,
          initialized_at: DateTime.utc_now()
        }
        
        # Simulate event publishing
        send(GreenhouseManager, {:greenhouse_initialized, event})
        {:ok, event}
        
      %Commands.ActivateGreenhouse{} = cmd ->
        event = %Events.GreenhouseActivated{
          greenhouse_id: cmd.greenhouse_id,
          activated_by: cmd.activated_by,
          activation_reason: cmd.activation_reason,
          target_conditions: cmd.target_conditions,
          activated_at: DateTime.utc_now()
        }
        
        send(GreenhouseManager, {:greenhouse_activated, event})
        {:ok, event}
        
      %Commands.DeactivateGreenhouse{} = cmd ->
        event = %Events.GreenhouseDeactivated{
          greenhouse_id: cmd.greenhouse_id,
          deactivated_by: cmd.deactivated_by,
          deactivation_reason: cmd.deactivation_reason,
          final_conditions: %{},
          deactivated_at: DateTime.utc_now()
        }
        
        send(GreenhouseManager, {:greenhouse_deactivated, event})
        {:ok, event}
        
      _ ->
        Logger.debug("ManageGreenhouse: Command type not handled in simulation")
        {:ok, :command_simulated}
    end
  end
end
