defmodule SimulateEquipment.GreenhouseEquipmentSimulator do
  @moduledoc """
  Runs the equipment simulation logic.

  Simulates various aspects such as:
  - Operational performance
  - Maintenance needs
  - Energy consumption
  - Failure scenarios
  - Equipment lifecycle management
  """

  use GenServer
  require Logger

  def start_link(greenhouse_id) do
    GenServer.start_link(__MODULE__, greenhouse_id, name: via_tuple(greenhouse_id))
  end

  @impl true
  def init(greenhouse_id) do
    Logger.info("GreenhouseEquipmentSimulator initializing for #{greenhouse_id}")

    {:ok, %{
      greenhouse_id: greenhouse_id,
      operational_conditions: %{},
      simulations: %{},
      maintenance_schedule: %{}
    }}
  end

  def start_equipment_simulation(pid, equipment_id, config) do
    GenServer.call(pid, {:start_equipment_simulation, equipment_id, config})
  end

  def stop_equipment_simulation(pid, equipment_id) do
    GenServer.call(pid, {:stop_equipment_simulation, equipment_id})
  end

  def update_operational_conditions(pid, conditions) do
    GenServer.cast(pid, {:update_operational_conditions, conditions})
  end

  def trigger_equipment_maintenance(pid, equipment_id, maintenance_type) do
    GenServer.cast(pid, {:trigger_equipment_maintenance, equipment_id, maintenance_type})
  end

  @impl true
  def handle_call({:start_equipment_simulation, equipment_id, config}, _from, state) do
    Logger.info("Starting simulation for equipment #{equipment_id}")

    new_simulations = Map.put(state.simulations, equipment_id, %{
      config: config,
      status: :running
    })

    {:reply, :ok, %{state | simulations: new_simulations}}
  end

  @impl true
  def handle_call({:stop_equipment_simulation, equipment_id}, _from, state) do
    Logger.info("Stopping simulation for equipment #{equipment_id}")

    new_simulations = Map.delete(state.simulations, equipment_id)

    {:reply, :ok, %{state | simulations: new_simulations}}
  end

  @impl true
  def handle_cast({:update_operational_conditions, conditions}, state) do
    Logger.info("Updating operational conditions for #{state.greenhouse_id}")
    
    {:noreply, %{state | operational_conditions: conditions}}
  end

  @impl true
  def handle_cast({:trigger_equipment_maintenance, equipment_id, maintenance_type}, state) do
    Logger.info("Triggering maintenance for equipment #{equipment_id}: #{maintenance_type}")

    {:noreply, state}
  end

  defp via_tuple(greenhouse_id) do
    {:via, Registry, {SimulateEquipment.Registry, "#{greenhouse_id}_equipment_simulator"}}
  end
end
