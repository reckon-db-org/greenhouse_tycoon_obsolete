defmodule GreenhouseTycoon.MeasureLight.LightMeasuredToGreenhouseEctoV1 do
  @moduledoc """
  Ecto projection for LightMeasured events.
  
  This projection updates greenhouse records with current light measurements.
  Following the vertical slicing architecture, this projection lives in the same slice
  as the event it processes.
  
  Naming follows the pattern: {event}_to_{target}_ecto_v{version}
  - Event: LightMeasured -> light_measured
  - Target: Greenhouse database table -> greenhouse_ecto
  """
  
  use Commanded.Projections.Ecto,
    application: GreenhouseTycoon.CommandedApp,
    repo: GreenhouseTycoon.Repo,
    name: "LightMeasuredToGreenhouseEctoV1"

  alias GreenhouseTycoon.MeasureLight.EventV1, as: LightMeasured
  alias GreenhouseTycoon.Greenhouse

  import Ecto.Query
  require Logger

  @doc """
  Projects LightMeasured events to update greenhouse light levels.
  
  Updates the current_light field and increments event_count.
  """
  project(%LightMeasured{} = event, _metadata, fn multi ->
    Logger.info("LightMeasuredToGreenhouseEctoV1: Updating light for #{event.greenhouse_id} to #{event.light}")
    
    multi
    |> Ecto.Multi.update_all(
      :greenhouse,
      from(g in Greenhouse, where: g.greenhouse_id == ^event.greenhouse_id),
      inc: [event_count: 1],
      set: [current_light: event.light]
    )
  end)
end