defmodule Simulator do
  @moduledoc """
  Greenhouse Simulator - A comprehensive simulation engine for greenhouse operations.
  
  This module provides the main API for the greenhouse simulator which simulates:
  - Crop growth and lifecycle management
  - Equipment aging and breakdown
  - Supply consumption and depletion
  - Environmental system responses (fans, sprinklers, lights)
  - Real-time calculations and event emission
  
  The simulator is event-driven and integrates with the event sourcing architecture
  to provide realistic greenhouse operation simulation.
  """

  alias Simulator.{CropEngine, EquipmentEngine, SupplyEngine, EnvironmentalEngine}
  alias Simulator.EventHandler
  require Logger

  @doc """
  Starts the simulation for a specific greenhouse.
  
  ## Parameters
  - `greenhouse_id`: The unique identifier for the greenhouse
  - `options`: Optional parameters for simulation configuration
  
  ## Returns
  - `{:ok, simulation_state}` on success
  - `{:error, reason}` on failure
  """
  def start_simulation(greenhouse_id, options \\ []) do
    Logger.info("Starting simulation for greenhouse: #{greenhouse_id}")
    
    with {:ok, initial_state} <- initialize_simulation_state(greenhouse_id, options),
         {:ok, _pid} <- Simulator.Supervisor.start_simulation(greenhouse_id, initial_state) do
      Logger.info("Simulation started successfully for greenhouse: #{greenhouse_id}")
      {:ok, initial_state}
    else
      error -> 
        Logger.error("Failed to start simulation for greenhouse #{greenhouse_id}: #{inspect(error)}")
        error
    end
  end

  @doc """
  Stops the simulation for a specific greenhouse.
  """
  def stop_simulation(greenhouse_id) do
    Logger.info("Stopping simulation for greenhouse: #{greenhouse_id}")
    Simulator.Supervisor.stop_simulation(greenhouse_id)
  end

  @doc """
  Gets the current simulation state for a greenhouse.
  """
  def get_simulation_state(greenhouse_id) do
    Simulator.SimulationServer.get_state(greenhouse_id)
  end

  @doc """
  Processes an external event in the simulation.
  
  This is the main entry point for event-driven simulation updates.
  """
  def handle_event(event, greenhouse_id) do
    Logger.debug("Handling event for greenhouse #{greenhouse_id}: #{inspect(event)}")
    EventHandler.handle_event(event, greenhouse_id)
  end

  @doc """
  Triggers a manual simulation step for testing/debugging.
  """
  def trigger_simulation_step(greenhouse_id) do
    Simulator.SimulationServer.trigger_step(greenhouse_id)
  end

  # Private helper functions
  
  defp initialize_simulation_state(greenhouse_id, options) do
    base_state = %{
      greenhouse_id: greenhouse_id,
      started_at: DateTime.utc_now(),
      simulation_speed: Keyword.get(options, :simulation_speed, 1.0),
      crops: CropEngine.initialize_state(),
      equipment: EquipmentEngine.initialize_state(),
      supplies: SupplyEngine.initialize_state(),
      environmental: EnvironmentalEngine.initialize_state(),
      last_update: DateTime.utc_now()
    }
    
    {:ok, base_state}
  end
end
