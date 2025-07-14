defmodule SimulateEquipment.SimulationCoordinator do
  @moduledoc """
  Coordinates equipment simulations across greenhouses.

  Manages the lifecycle of individual equipment simulation processes
  and handles cross-greenhouse simulation coordination.
  """

  use GenServer
  require Logger

  alias SimulateEquipment.GreenhouseEquipmentSimulator

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    Logger.info("SimulateEquipment.SimulationCoordinator: Starting simulation coordinator")

    {:ok, %{
      greenhouse_simulators: %{},
      equipment_simulations: %{}
    }}
  end

  # Public API

  def initialize_greenhouse_simulation(greenhouse_id, config) do
    GenServer.call(__MODULE__, {:initialize_greenhouse, greenhouse_id, config})
  end

  def start_equipment_simulation(greenhouse_id, equipment_id, equipment_config) do
    GenServer.call(__MODULE__, {:start_equipment_simulation, greenhouse_id, equipment_id, equipment_config})
  end

  def stop_equipment_simulation(greenhouse_id, equipment_id) do
    GenServer.call(__MODULE__, {:stop_equipment_simulation, greenhouse_id, equipment_id})
  end

  def stop_greenhouse_simulation(greenhouse_id) do
    GenServer.call(__MODULE__, {:stop_greenhouse_simulation, greenhouse_id})
  end

  def update_operational_conditions(greenhouse_id, conditions) do
    GenServer.cast(__MODULE__, {:update_operations, greenhouse_id, conditions})
  end

  def trigger_equipment_maintenance(greenhouse_id, equipment_id, maintenance_type) do
    GenServer.cast(__MODULE__, {:trigger_maintenance, greenhouse_id, equipment_id, maintenance_type})
  end

  def get_simulation_status(greenhouse_id) do
    GenServer.call(__MODULE__, {:get_status, greenhouse_id})
  end

  # GenServer callbacks

  def handle_call({:initialize_greenhouse, greenhouse_id, config}, _from, state) do
    Logger.info("SimulationCoordinator: Initializing greenhouse simulation for #{greenhouse_id}")

    # Start a greenhouse equipment simulator
    simulator_spec = {
      GreenhouseEquipmentSimulator,
      [greenhouse_id: greenhouse_id, config: config]
    }

    case DynamicSupervisor.start_child(SimulateEquipment.SimulationSupervisor, simulator_spec) do
      {:ok, pid} ->
        new_state = %{
          state |
          greenhouse_simulators: Map.put(state.greenhouse_simulators, greenhouse_id, pid)
        }
        {:reply, {:ok, pid}, new_state}

      {:error, reason} ->
        Logger.error("SimulationCoordinator: Failed to start greenhouse simulator: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:start_equipment_simulation, greenhouse_id, equipment_id, equipment_config}, _from, state) do
    Logger.info("SimulationCoordinator: Starting equipment simulation for #{equipment_id} in #{greenhouse_id}")

    case Map.get(state.greenhouse_simulators, greenhouse_id) do
      nil ->
        Logger.warning("SimulationCoordinator: No greenhouse simulator found for #{greenhouse_id}")
        {:reply, {:error, :greenhouse_not_found}, state}

      simulator_pid ->
        # Delegate to the greenhouse simulator
        result = GreenhouseEquipmentSimulator.start_equipment_simulation(simulator_pid, equipment_id, equipment_config)

        # Track the equipment simulation
        equipment_key = {greenhouse_id, equipment_id}
        new_state = %{
          state |
          equipment_simulations: Map.put(state.equipment_simulations, equipment_key, %{
            started_at: DateTime.utc_now(),
            config: equipment_config,
            status: :active
          })
        }

        {:reply, result, new_state}
    end
  end

  def handle_call({:stop_equipment_simulation, greenhouse_id, equipment_id}, _from, state) do
    Logger.info("SimulationCoordinator: Stopping equipment simulation for #{equipment_id} in #{greenhouse_id}")

    case Map.get(state.greenhouse_simulators, greenhouse_id) do
      nil ->
        {:reply, {:error, :greenhouse_not_found}, state}

      simulator_pid ->
        result = GreenhouseEquipmentSimulator.stop_equipment_simulation(simulator_pid, equipment_id)

        # Remove equipment simulation tracking
        equipment_key = {greenhouse_id, equipment_id}
        new_state = %{
          state |
          equipment_simulations: Map.delete(state.equipment_simulations, equipment_key)
        }

        {:reply, result, new_state}
    end
  end

  def handle_call({:stop_greenhouse_simulation, greenhouse_id}, _from, state) do
    Logger.info("SimulationCoordinator: Stopping greenhouse simulation for #{greenhouse_id}")

    case Map.get(state.greenhouse_simulators, greenhouse_id) do
      nil ->
        {:reply, {:error, :greenhouse_not_found}, state}

      simulator_pid ->
        # Stop the greenhouse simulator
        DynamicSupervisor.terminate_child(SimulateEquipment.SimulationSupervisor, simulator_pid)

        # Clean up tracking
        new_state = %{
          state |
          greenhouse_simulators: Map.delete(state.greenhouse_simulators, greenhouse_id),
          equipment_simulations: Map.reject(state.equipment_simulations, fn {{gh_id, _equipment_id}, _config} ->
            gh_id == greenhouse_id
          end)
        }

        {:reply, :ok, new_state}
    end
  end

  def handle_call({:get_status, greenhouse_id}, _from, state) do
    status = %{
      greenhouse_active: Map.has_key?(state.greenhouse_simulators, greenhouse_id),
      active_equipment: state.equipment_simulations
        |> Enum.filter(fn {{gh_id, _equipment_id}, _config} -> gh_id == greenhouse_id end)
        |> Enum.map(fn {{_gh_id, equipment_id}, config} -> {equipment_id, config} end)
    }

    {:reply, status, state}
  end

  def handle_cast({:update_operations, greenhouse_id, conditions}, state) do
    case Map.get(state.greenhouse_simulators, greenhouse_id) do
      nil ->
        Logger.debug("SimulationCoordinator: No greenhouse simulator to update for #{greenhouse_id}")

      simulator_pid ->
        GreenhouseEquipmentSimulator.update_operational_conditions(simulator_pid, conditions)
    end

    {:noreply, state}
  end

  def handle_cast({:trigger_maintenance, greenhouse_id, equipment_id, maintenance_type}, state) do
    case Map.get(state.greenhouse_simulators, greenhouse_id) do
      nil ->
        Logger.debug("SimulationCoordinator: No greenhouse simulator found for maintenance in #{greenhouse_id}")

      simulator_pid ->
        GreenhouseEquipmentSimulator.trigger_equipment_maintenance(simulator_pid, equipment_id, maintenance_type)
    end

    {:noreply, state}
  end
end
