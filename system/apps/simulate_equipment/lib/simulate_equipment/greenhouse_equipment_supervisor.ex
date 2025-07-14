defmodule SimulateEquipment.GreenhouseEquipmentSupervisor do
  @moduledoc """
  Supervises greenhouse-specific equipment simulation processes.

  This supervisor manages:
  - GreenhouseEquipmentEventListener: Listens for equipment-related events for a specific greenhouse
  - GreenhouseEquipmentSimulationCoordinator: Coordinates equipment simulation lifecycle
  - GreenhouseEquipmentSimulator: Runs the equipment simulation logic
  """

  use Supervisor
  alias __MODULE__
  require Logger

  def start_link(greenhouse_id) do
    Supervisor.start_link(__MODULE__, greenhouse_id, name: via_tuple(greenhouse_id))
  end

  @impl true
  def init(greenhouse_id) do
    children = [
      {SimulateEquipment.GreenhouseEquipmentEventListener, greenhouse_id},
      {SimulateEquipment.GreenhouseEquipmentSimulationCoordinator, greenhouse_id},
      {SimulateEquipment.GreenhouseEquipmentSimulator, greenhouse_id}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  defp via_tuple(greenhouse_id) do
    {:via, Registry, {SimulateEquipment.Registry, "#{greenhouse_id}_equipment_supervisor"}}
  end
end
