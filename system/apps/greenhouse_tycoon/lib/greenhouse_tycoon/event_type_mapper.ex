defmodule GreenhouseTycoon.EventTypeMapper do
  @moduledoc """
  Maps event modules to their type strings for ExESDB serialization.
  
  Event types follow the format: <event_type>:<version> in snake_case
  Example: "greenhouse_initialized:v1"
  
  Following The Guidelines, each event module maps to a versioned event type.
  
  This module implements the required ExESDB.Commanded.EventTypeMapper behavior
  and provides additional debugging utilities for reverse mapping.
  """
  @behaviour ExESDB.Commanded.EventTypeMapper

  # Define the mapping table for easy maintenance and reverse lookups
  @mappings [
    {GreenhouseTycoon.InitializeGreenhouse.EventV1, "greenhouse_initialized:v1"},
    {GreenhouseTycoon.SetTargetTemperature.EventV1, "target_temperature_set:v1"},
    {GreenhouseTycoon.SetTargetHumidity.EventV1, "target_humidity_set:v1"},
    {GreenhouseTycoon.SetTargetLight.EventV1, "target_light_set:v1"},
    {GreenhouseTycoon.MeasureTemperature.EventV1, "temperature_measured:v1"},
    {GreenhouseTycoon.MeasureHumidity.EventV1, "humidity_measured:v1"},
    {GreenhouseTycoon.MeasureLight.EventV1, "light_measured:v1"}
  ]

  # Required by ExESDB.Commanded.EventTypeMapper behavior
  @impl ExESDB.Commanded.EventTypeMapper
  def to_event_type(event_module) do
    case Enum.find(@mappings, fn {module, _type} -> module == event_module end) do
      {_module, event_type} -> event_type
      nil -> raise "Unknown event module: #{inspect(event_module)}"
    end
  end

  @doc """
  Reverse mapping from event type string to event module.
  Useful for debugging and REPL utilities.
  """
  def from_event_type(event_type) do
    case Enum.find(@mappings, fn {_module, type} -> type == event_type end) do
      {event_module, _type} -> event_module
      nil -> raise "Unknown event type: #{inspect(event_type)}"
    end
  end

  @doc """
  Returns all module-to-event-type mappings.
  Useful for debugging and REPL utilities.
  """
  def mappings, do: @mappings

  @doc """
  Returns all supported event types.
  """
  def event_types do
    Enum.map(@mappings, fn {_module, event_type} -> event_type end)
  end

  @doc """
  Returns all supported event modules.
  """
  def event_modules do
    Enum.map(@mappings, fn {event_module, _type} -> event_module end)
  end
end
