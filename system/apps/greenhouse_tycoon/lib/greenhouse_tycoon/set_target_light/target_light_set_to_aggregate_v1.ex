defmodule GreenhouseTycoon.SetTargetLight.TargetLightSetToAggregateV1 do
  @moduledoc """
  Aggregate event handler for TargetLightSet events.
  
  This handler mutates the Greenhouse aggregate state when target light is changed.
  Following the vertical slicing architecture, this handler lives in the same slice
  as the event it processes.
  
  Naming follows the refined pattern: {event}_to_aggregate_v{version}
  - Event: LightSet -> light_set
  - Aggregate: Always named 'aggregate' -> aggregate
  """
  
  alias GreenhouseTycoon.Aggregate
  alias GreenhouseTycoon.SetTargetLight.EventV1, as: TargetLightSetEvent
  
  require Logger
  
  @doc """
  Applies the TargetLightSet event to the Greenhouse aggregate state.
  
  This updates the target light in the aggregate state.
  """
  def apply(%Aggregate{} = greenhouse, %TargetLightSetEvent{} = event) do
    Logger.info("TargetLightSetToAggregateV1: Applying TargetLightSet event for #{event.greenhouse_id} to #{event.target_light} lumens")
    Logger.debug("TargetLightSetToAggregateV1: Event data: #{inspect(event)}")

    updated_state = %Aggregate{
      greenhouse
      | target_light: event.target_light,
        updated_at: event.set_at
    }

    Logger.info("TargetLightSetToAggregateV1: Updated state greenhouse_id: #{updated_state.greenhouse_id}")
    updated_state
  end
end
