defmodule SimulateEquipment.GreenhouseEquipmentEventListener do
  @moduledoc """
  Listens for equipment-related events for a specific greenhouse.

  This process subscribes to equipment operation and maintenance events
  and coordinates with the equipment simulator to update simulation state.
  """

  use GenServer
  require Logger

  def start_link(greenhouse_id) do
    GenServer.start_link(__MODULE__, greenhouse_id, name: via_tuple(greenhouse_id))
  end

  @impl true
  def init(greenhouse_id) do
    # Subscribe to equipment events for this greenhouse
    Phoenix.PubSub.subscribe(SimulateEquipment.PubSub, "greenhouse:#{greenhouse_id}:equipment")
    Phoenix.PubSub.subscribe(SimulateEquipment.PubSub, "equipment:maintenance")
    Phoenix.PubSub.subscribe(SimulateEquipment.PubSub, "equipment:operations")

    Logger.info("GreenhouseEquipmentEventListener started for greenhouse #{greenhouse_id}")

    {:ok, %{greenhouse_id: greenhouse_id, equipment_status: %{}}}
  end

  @impl true
  def handle_info({:equipment_installed, greenhouse_id, equipment_id, equipment_spec}, state) when greenhouse_id == state.greenhouse_id do
    Logger.info("Equipment #{equipment_id} installed in greenhouse #{greenhouse_id}")

    # Start simulation for this equipment
    notify_simulator({:start_equipment_simulation, equipment_id, equipment_spec}, state)

    updated_status = Map.put(state.equipment_status, equipment_id, %{
      status: :installed,
      spec: equipment_spec,
      installed_at: DateTime.utc_now()
    })

    {:noreply, %{state | equipment_status: updated_status}}
  end

  @impl true
  def handle_info({:equipment_activated, greenhouse_id, equipment_id}, state) when greenhouse_id == state.greenhouse_id do
    Logger.info("Equipment #{equipment_id} activated in greenhouse #{greenhouse_id}")

    notify_simulator({:activate_equipment, equipment_id}, state)

    updated_status = put_in(state.equipment_status, [equipment_id, :status], :active)
    {:noreply, %{state | equipment_status: updated_status}}
  end

  @impl true
  def handle_info({:equipment_deactivated, greenhouse_id, equipment_id}, state) when greenhouse_id == state.greenhouse_id do
    Logger.info("Equipment #{equipment_id} deactivated in greenhouse #{greenhouse_id}")

    notify_simulator({:deactivate_equipment, equipment_id}, state)

    updated_status = put_in(state.equipment_status, [equipment_id, :status], :inactive)
    {:noreply, %{state | equipment_status: updated_status}}
  end

  @impl true
  def handle_info({:equipment_removed, greenhouse_id, equipment_id}, state) when greenhouse_id == state.greenhouse_id do
    Logger.info("Equipment #{equipment_id} removed from greenhouse #{greenhouse_id}")

    # Stop simulation for this equipment
    notify_simulator({:stop_equipment_simulation, equipment_id}, state)

    updated_status = Map.delete(state.equipment_status, equipment_id)
    {:noreply, %{state | equipment_status: updated_status}}
  end

  @impl true
  def handle_info({:maintenance_scheduled, greenhouse_id, equipment_id, maintenance_type}, state) when greenhouse_id == state.greenhouse_id do
    Logger.info("Maintenance scheduled for equipment #{equipment_id} in greenhouse #{greenhouse_id}: #{maintenance_type}")

    notify_simulator({:schedule_maintenance, equipment_id, maintenance_type}, state)

    {:noreply, state}
  end

  @impl true
  def handle_info({:maintenance_completed, greenhouse_id, equipment_id, maintenance_type}, state) when greenhouse_id == state.greenhouse_id do
    Logger.info("Maintenance completed for equipment #{equipment_id} in greenhouse #{greenhouse_id}: #{maintenance_type}")

    notify_simulator({:complete_maintenance, equipment_id, maintenance_type}, state)

    {:noreply, state}
  end

  @impl true
  def handle_info({:operation_command, greenhouse_id, equipment_id, command, params}, state) when greenhouse_id == state.greenhouse_id do
    Logger.info("Operation command for equipment #{equipment_id} in greenhouse #{greenhouse_id}: #{command}")

    notify_simulator({:execute_operation, equipment_id, command, params}, state)

    {:noreply, state}
  end

  @impl true
  def handle_info(event, state) do
    Logger.debug("GreenhouseEquipmentEventListener ignoring event: #{inspect(event)}")
    {:noreply, state}
  end

  defp notify_simulator(message, state) do
    case Registry.lookup(SimulateEquipment.Registry, "#{state.greenhouse_id}_equipment_simulator") do
      [{pid, _}] ->
        GenServer.cast(pid, message)

      [] ->
        Logger.warning("No equipment simulator found for greenhouse #{state.greenhouse_id}")
    end
  end

  defp via_tuple(greenhouse_id) do
    {:via, Registry, {SimulateEquipment.Registry, "#{greenhouse_id}_equipment_event_listener"}}
  end
end
