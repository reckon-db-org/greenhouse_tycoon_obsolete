defmodule SimulateCrops.GreenhouseCropSupervisor do
  @moduledoc """
  Supervises greenhouse-specific crop simulation processes.

  This supervisor manages:
  - GreenhouseCropEventListener: Listens for crop-related events for a specific greenhouse
  - GreenhouseCropSimulationCoordinator: Coordinates crop simulation lifecycle
  - GreenhouseCropSimulator: Runs the crop simulation logic
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
      {SimulateCrops.GreenhouseCropEventListener, greenhouse_id},
      {SimulateCrops.GreenhouseCropSimulationCoordinator, greenhouse_id},
      {SimulateCrops.GreenhouseCropSimulator, greenhouse_id}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  defp via_tuple(greenhouse_id) do
    {:via, Registry, {SimulateCrops.Registry, "#{greenhouse_id}_crop_supervisor"}}
  end
end

