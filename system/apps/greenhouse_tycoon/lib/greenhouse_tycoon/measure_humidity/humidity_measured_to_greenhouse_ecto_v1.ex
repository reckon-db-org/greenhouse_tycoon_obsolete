defmodule GreenhouseTycoon.MeasureHumidity.HumidityMeasuredToGreenhouseEctoV1 do
  @moduledoc """
  Ecto projection for HumidityMeasured events.
  
  This projection updates greenhouse records with current humidity measurements.
  Following the vertical slicing architecture, this projection lives in the same slice
  as the event it processes.
  
  Naming follows the pattern: {event}_to_{target}_ecto_v{version}
  - Event: HumidityMeasured -> humidity_measured
  - Target: Greenhouse database table -> greenhouse_ecto
  """
  
  use Commanded.Projections.Ecto,
    application: GreenhouseTycoon.CommandedApp,
    repo: GreenhouseTycoon.Repo,
    name: "HumidityMeasuredToGreenhouseEctoV1"

  alias GreenhouseTycoon.MeasureHumidity.EventV1, as: HumidityMeasured
  alias GreenhouseTycoon.Greenhouse

  import Ecto.Query
  require Logger

  @doc """
  Projects HumidityMeasured events to update greenhouse humidity.
  
  Updates the current_humidity field and increments event_count.
  """
  project(%HumidityMeasured{} = event, _metadata, fn multi ->
    Logger.info("HumidityMeasuredToGreenhouseEctoV1: Updating humidity for #{event.greenhouse_id} to #{event.humidity}")
    
    multi
    |> Ecto.Multi.update_all(
      :greenhouse,
      from(g in Greenhouse, where: g.greenhouse_id == ^event.greenhouse_id),
      inc: [event_count: 1],
      set: [current_humidity: event.humidity]
    )
  end)
end