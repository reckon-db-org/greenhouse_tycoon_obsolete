defmodule GreenhouseTycoon.InitializeGreenhouse.InitializedToAggregateV1 do
  @moduledoc """
  Aggregate event handler for GreenhouseInitialized events.
  
  This handler mutates the Greenhouse aggregate state when a greenhouse is initialized.
  Following the vertical slicing architecture, this handler lives in the same slice
  as the event it processes.
  
  Naming follows the refined pattern: {event}_to_aggregate_v{version}
  - Event: GreenhouseInitialized -> initialized
  - Aggregate: Always named 'aggregate' -> aggregate
  """
  
  alias GreenhouseTycoon.Greenhouse
  alias GreenhouseTycoon.InitializeGreenhouse.EventV1, as: GreenhouseInitializedEvent
  
  require Logger
  
  @doc """
  Applies the GreenhouseInitialized event to the Greenhouse aggregate state.
  
  This creates the initial state of a new greenhouse aggregate.
  """
  def apply(%Greenhouse{} = _greenhouse, %GreenhouseInitializedEvent{} = event) do
    Logger.info("InitializedToAggregateV1: Applying GreenhouseInitialized event for #{event.greenhouse_id}")
    Logger.debug("InitializedToAggregateV1: Event data: #{inspect(event)}")

    new_state = %Greenhouse{
      greenhouse_id: event.greenhouse_id,
      name: event.name,
      location: event.location,
      city: event.city,
      country: event.country,
      target_temperature: event.target_temperature,
      target_humidity: event.target_humidity,
      target_light: event.target_light,
      current_temperature: nil,
      current_humidity: nil,
      current_light: nil,
      created_at: event.initialized_at,
      updated_at: event.initialized_at
    }

    Logger.info("InitializedToAggregateV1: New state greenhouse_id: #{new_state.greenhouse_id}")
    new_state
  end
end
