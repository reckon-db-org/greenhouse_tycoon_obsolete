defmodule GreenhouseTycoon.InitializeGreenhouse.InitializedToGreenhouseEctoV1 do
  @moduledoc """
  Ecto projection for GreenhouseInitialized events.
  
  This projection creates greenhouse records in the database when greenhouses are initialized.
  Following the vertical slicing architecture, this projection lives in the same slice
  as the event it processes.
  
  Naming follows the pattern: {event}_to_{target}_ecto_v{version}
  - Event: GreenhouseInitialized -> initialized
  - Target: Greenhouse database table -> greenhouse_ecto
  """
  
  use Commanded.Projections.Ecto,
    application: GreenhouseTycoon.CommandedApp,
    repo: GreenhouseTycoon.Repo,
    name: "InitializedToGreenhouseEctoV1"

  alias GreenhouseTycoon.InitializeGreenhouse.EventV1, as: GreenhouseInitialized
  alias GreenhouseTycoon.Greenhouse

  require Logger

  @doc """
  Projects GreenhouseInitialized events to the greenhouse database table.
  
  Creates a new greenhouse record with initial state.
  """
  project(%GreenhouseInitialized{} = event, _metadata, fn multi ->
    Logger.info("InitializedToGreenhouseEctoV1: Projecting GreenhouseInitialized for #{event.greenhouse_id}")
    
    greenhouse = %Greenhouse{
      greenhouse_id: event.greenhouse_id,
      name: event.name,
      location: event.location,
      city: event.city,
      country: event.country,
      target_temperature: event.target_temperature,
      target_humidity: event.target_humidity,
      target_light: event.target_light,
      status: 2,  # inactive status
      event_count: 1
    }

    multi
    |> Ecto.Multi.insert(
      :greenhouse,
      greenhouse,
      on_conflict: :nothing,  # Idempotent
      conflict_target: [:greenhouse_id]
    )
  end)
end