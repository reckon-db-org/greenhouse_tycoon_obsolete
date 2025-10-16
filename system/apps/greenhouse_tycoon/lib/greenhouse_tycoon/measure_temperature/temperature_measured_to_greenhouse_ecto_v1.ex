defmodule GreenhouseTycoon.MeasureTemperature.TemperatureMeasuredToGreenhouseEctoV1 do
  @moduledoc """
  Ecto projection for TemperatureMeasured events.
  
  This projection updates greenhouse records with current temperature measurements.
  Following the vertical slicing architecture, this projection lives in the same slice
  as the event it processes.
  
  Naming follows the pattern: {event}_to_{target}_ecto_v{version}
  - Event: TemperatureMeasured -> temperature_measured
  - Target: Greenhouse database table -> greenhouse_ecto
  """
  
  use Commanded.Projections.Ecto,
    application: GreenhouseTycoon.CommandedApp,
    repo: GreenhouseTycoon.Repo,
    name: "TemperatureMeasuredToGreenhouseEctoV1"

  alias GreenhouseTycoon.MeasureTemperature.EventV1, as: TemperatureMeasured
  alias GreenhouseTycoon.Greenhouse

  import Ecto.Query
  require Logger

  @doc """
  Projects TemperatureMeasured events to update greenhouse temperature.
  
  Updates the current_temperature field and increments event_count.
  """
  project(%TemperatureMeasured{} = event, _metadata, fn multi ->
    Logger.info("TemperatureMeasuredToGreenhouseEctoV1: Updating temperature for #{event.greenhouse_id} to #{event.temperature}")
    
    multi
    |> Ecto.Multi.update_all(
      :greenhouse,
      from(g in Greenhouse, where: g.greenhouse_id == ^event.greenhouse_id),
      inc: [event_count: 1],
      set: [current_temperature: event.temperature]
    )
  end)
end