defmodule GreenhouseTycoon.SetTargetTemperature.TargetTemperatureSetToAggregateV1 do
  @moduledoc """
  Aggregate event handler for TargetTemperatureSet events.
  
  This handler mutates the Greenhouse aggregate state when target temperature is changed.
  Following the vertical slicing architecture, this handler lives in the same slice
  as the event it processes.
  
  Naming follows the refined pattern: {event}_to_aggregate_v{version}
  - Event: TargetTemperatureSet -> target_temperature_set
  - Aggregate: Always named 'aggregate' -> aggregate
  """
  
  alias GreenhouseTycoon.Aggregate
  alias GreenhouseTycoon.SetTargetTemperature.EventV1, as: TargetTemperatureSetEvent
  
  require Logger
  
  @doc """
  Applies the TargetTemperatureSet event to the Greenhouse aggregate state.
  
  This updates the target temperature in the aggregate state.
  """
  def apply(%Aggregate{} = greenhouse, %TargetTemperatureSetEvent{} = event) do
    Logger.info("TargetTemperatureSetToAggregateV1: Applying TargetTemperatureSet event for #{event.greenhouse_id} to #{event.target_temperature}°C")
    Logger.debug("TargetTemperatureSetToAggregateV1: Event data: #{inspect(event)}")

    updated_state = %Aggregate{
      greenhouse
      | target_temperature: event.target_temperature,
        updated_at: event.set_at
    }

    Logger.info("TargetTemperatureSetToAggregateV1: Updated state greenhouse_id: #{updated_state.greenhouse_id}")
    updated_state
  end
end
