defmodule GreenhouseTycoon.MeasureTemperature.TemperatureMeasuredToAggregateV1 do
  @moduledoc """
  Aggregate event handler for TemperatureMeasured events.
  
  This handler mutates the Greenhouse aggregate state when temperature measurements are recorded.
  Following the vertical slicing architecture, this handler lives in the same slice
  as the event it processes.
  
  Naming follows the refined pattern: {event}_to_aggregate_v{version}
  - Event: TemperatureMeasured -> temperature_measured
  - Aggregate: Always named 'aggregate' -> aggregate
  """
  
  alias GreenhouseTycoon.Greenhouse
  alias GreenhouseTycoon.MeasureTemperature.EventV1, as: TemperatureMeasuredEvent
  
  require Logger
  
  @doc """
  Applies the TemperatureMeasured event to the Greenhouse aggregate state.
  
  This updates the current temperature in the aggregate state.
  """
  def apply(%Greenhouse{} = greenhouse, %TemperatureMeasuredEvent{} = event) do
    Logger.info("TemperatureMeasuredToAggregateV1: Applying TemperatureMeasured event for #{event.greenhouse_id}: #{event.temperature}°C")
    Logger.debug("TemperatureMeasuredToAggregateV1: Event data: #{inspect(event)}")

    updated_state = %Greenhouse{
      greenhouse
      | current_temperature: event.temperature,
        updated_at: event.measured_at
    }

    Logger.info("TemperatureMeasuredToAggregateV1: Updated state greenhouse_id: #{updated_state.greenhouse_id}")
    updated_state
  end
end
