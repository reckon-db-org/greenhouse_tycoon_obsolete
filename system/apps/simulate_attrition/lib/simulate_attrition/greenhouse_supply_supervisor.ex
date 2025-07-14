defmodule SimulateAttrition.GreenhouseSupplySupervisor do
  @moduledoc """
  Supervises greenhouse-specific supply attrition simulation processes.

  This supervisor manages:
  - GreenhouseSupplyEventListener: Listens for supply-related events for a specific greenhouse
  - GreenhouseSupplySimulationCoordinator: Coordinates supply simulation lifecycle
  - GreenhouseSupplySimulator: Runs the supply attrition simulation logic
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
      {SimulateAttrition.GreenhouseSupplyEventListener, greenhouse_id},
      {SimulateAttrition.GreenhouseSupplySimulationCoordinator, greenhouse_id},
      {SimulateAttrition.GreenhouseSupplySimulator, greenhouse_id}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  defp via_tuple(greenhouse_id) do
    {:via, Registry, {SimulateAttrition.Registry, "#{greenhouse_id}_supply_supervisor"}}
  end
end
