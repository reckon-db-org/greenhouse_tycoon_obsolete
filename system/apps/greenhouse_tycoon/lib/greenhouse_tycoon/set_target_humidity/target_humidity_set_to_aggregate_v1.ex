defmodule GreenhouseTycoon.SetTargetHumidity.TargetHumiditySetToAggregateV1 do
  @moduledoc """
  Aggregate event handler for TargetHumiditySet events.
  
  This handler mutates the Greenhouse aggregate state when target humidity is changed.
  Following the vertical slicing architecture, this handler lives in the same slice
  as the event it processes.
  
  Naming follows the refined pattern: {event}_to_aggregate_v{version}
  - Event: HumiditySet -> humidity_set
  - Aggregate: Always named 'aggregate' -> aggregate
  """
  
  alias GreenhouseTycoon.Aggregate
  alias GreenhouseTycoon.SetTargetHumidity.EventV1, as: TargetHumiditySetEvent
  
  require Logger
  
  @doc """
  Applies the TargetHumiditySet event to the Greenhouse aggregate state.
  
  This updates the target humidity in the aggregate state.
  """
  def apply(%Aggregate{} = greenhouse, %TargetHumiditySetEvent{} = event) do
    Logger.info("TargetHumiditySetToAggregateV1: Applying TargetHumiditySet event for #{event.greenhouse_id} to #{event.target_humidity}%")
    Logger.debug("TargetHumiditySetToAggregateV1: Event data: #{inspect(event)}")

    updated_state = %Aggregate{
      greenhouse
      | target_humidity: event.target_humidity,
        updated_at: event.set_at
    }

    Logger.info("TargetHumiditySetToAggregateV1: Updated state greenhouse_id: #{updated_state.greenhouse_id}")
    updated_state
  end
end
