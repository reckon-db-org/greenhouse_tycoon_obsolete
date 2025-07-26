defmodule GreenhouseTycoon.EventTypeMapper do
  @moduledoc """
  Maps event modules to their type strings for ExESDB serialization.
  
  Event types follow the format: <event_type>:<version> in snake_case
  Example: "greenhouse_initialized:v1"
  
  Following The Guidelines, each event module maps to a versioned event type.
  """
  @behaviour ExESDB.Commanded.EventTypeMapper

  @impl ExESDB.Commanded.EventTypeMapper
  def to_event_type(GreenhouseTycoon.InitializeGreenhouse.EventV1), do: "greenhouse_initialized:v1"
  def to_event_type(GreenhouseTycoon.SetTargetTemperature.EventV1), do: "target_temperature_set:v1"
  def to_event_type(GreenhouseTycoon.SetTargetHumidity.EventV1), do: "target_humidity_set:v1"
  def to_event_type(GreenhouseTycoon.SetTargetLight.EventV1), do: "target_light_set:v1"
  def to_event_type(GreenhouseTycoon.MeasureTemperature.EventV1), do: "temperature_measured:v1"
  def to_event_type(GreenhouseTycoon.MeasureHumidity.EventV1), do: "humidity_measured:v1"
  def to_event_type(GreenhouseTycoon.MeasureLight.EventV1), do: "light_measured:v1"
  def to_event_type(event_module), do: raise "Unknown event module: #{event_module}"
end
