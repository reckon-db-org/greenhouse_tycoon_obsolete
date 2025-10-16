defmodule GreenhouseTycoon.SetTargetTemperature.TargetTemperatureSetToGreenhouseEctoV1 do
  @moduledoc """
  Ecto projection for TargetTemperatureSet events.
  
  This projection updates greenhouse records with new temperature targets.
  Following the vertical slicing architecture, this projection lives in the same slice
  as the event it processes.
  
  Naming follows the pattern: {event}_to_{target}_ecto_v{version}
  - Event: TargetTemperatureSet -> target_temperature_set
  - Target: Greenhouse database table -> greenhouse_ecto
  """
  
  use Commanded.Projections.Ecto,
    application: GreenhouseTycoon.CommandedApp,
    repo: GreenhouseTycoon.Repo,
    name: "TargetTemperatureSetToGreenhouseEctoV1"

  alias GreenhouseTycoon.SetTargetTemperature.EventV1, as: TargetTemperatureSet
  alias GreenhouseTycoon.Greenhouse

  import Ecto.Query
  require Logger

  @doc """
  Projects TargetTemperatureSet events to update greenhouse target temperature.
  
  Updates the target_temperature field and increments event_count.
  """
  project(%TargetTemperatureSet{} = event, _metadata, fn multi ->
    Logger.info("TargetTemperatureSetToGreenhouseEctoV1: Setting target temperature for #{event.greenhouse_id} to #{event.target_temperature}")
    
    multi
    |> Ecto.Multi.update_all(
      :greenhouse,
      from(g in Greenhouse, where: g.greenhouse_id == ^event.greenhouse_id),
      set: [target_temperature: event.target_temperature],
      inc: [event_count: 1]
    )
  end)
end