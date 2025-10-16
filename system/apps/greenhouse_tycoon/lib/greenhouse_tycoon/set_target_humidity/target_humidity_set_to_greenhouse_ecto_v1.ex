defmodule GreenhouseTycoon.SetTargetHumidity.TargetHumiditySetToGreenhouseEctoV1 do
  @moduledoc """
  Ecto projection for TargetHumiditySet events.
  
  This projection updates greenhouse records with new humidity targets.
  Following the vertical slicing architecture, this projection lives in the same slice
  as the event it processes.
  
  Naming follows the pattern: {event}_to_{target}_ecto_v{version}
  - Event: TargetHumiditySet -> target_humidity_set
  - Target: Greenhouse database table -> greenhouse_ecto
  """
  
  use Commanded.Projections.Ecto,
    application: GreenhouseTycoon.CommandedApp,
    repo: GreenhouseTycoon.Repo,
    name: "TargetHumiditySetToGreenhouseEctoV1"

  alias GreenhouseTycoon.SetTargetHumidity.EventV1, as: TargetHumiditySet
  alias GreenhouseTycoon.Greenhouse

  import Ecto.Query
  require Logger

  @doc """
  Projects TargetHumiditySet events to update greenhouse target humidity.
  
  Updates the target_humidity field and increments event_count.
  """
  project(%TargetHumiditySet{} = event, _metadata, fn multi ->
    Logger.info("TargetHumiditySetToGreenhouseEctoV1: Setting target humidity for #{event.greenhouse_id} to #{event.target_humidity}")
    
    multi
    |> Ecto.Multi.update_all(
      :greenhouse,
      from(g in Greenhouse, where: g.greenhouse_id == ^event.greenhouse_id),
      set: [target_humidity: event.target_humidity],
      inc: [event_count: 1]
    )
  end)
end