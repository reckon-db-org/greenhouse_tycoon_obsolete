defmodule GreenhouseTycoon.SetTargetLight.TargetLightSetToGreenhouseEctoV1 do
  @moduledoc """
  Ecto projection for TargetLightSet events.
  
  This projection updates greenhouse records with new light targets.
  Following the vertical slicing architecture, this projection lives in the same slice
  as the event it processes.
  
  Naming follows the pattern: {event}_to_{target}_ecto_v{version}
  - Event: TargetLightSet -> target_light_set
  - Target: Greenhouse database table -> greenhouse_ecto
  """
  
  use Commanded.Projections.Ecto,
    application: GreenhouseTycoon.CommandedApp,
    repo: GreenhouseTycoon.Repo,
    name: "TargetLightSetToGreenhouseEctoV1"

  alias GreenhouseTycoon.SetTargetLight.EventV1, as: TargetLightSet
  alias GreenhouseTycoon.Greenhouse

  import Ecto.Query
  require Logger

  @doc """
  Projects TargetLightSet events to update greenhouse target light levels.
  
  Updates the target_light field and increments event_count.
  """
  project(%TargetLightSet{} = event, _metadata, fn multi ->
    Logger.info("TargetLightSetToGreenhouseEctoV1: Setting target light for #{event.greenhouse_id} to #{event.target_light}")
    
    multi
    |> Ecto.Multi.update_all(
      :greenhouse,
      from(g in Greenhouse, where: g.greenhouse_id == ^event.greenhouse_id),
      set: [target_light_level: event.target_light],
      inc: [event_count: 1]
    )
  end)
end