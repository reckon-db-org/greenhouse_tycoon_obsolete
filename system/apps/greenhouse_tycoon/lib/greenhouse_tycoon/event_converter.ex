defmodule GreenhouseTycoon.EventConverter do
  @moduledoc """
  Utilizes the ExESDB Commanded Adapter's robust event conversion.
  
  This module replaces the previous CommandedPatch by leveraging the adapter's
  more sophisticated conversion logic, which includes:
  - Proper ExESDB 0-based to Commanded 1-based version conversion
  - Robust metadata parsing for various formats (binary JSON, maps, nil)
  - Better error handling and fallback logic
  """

  alias ExESDB.Commanded.Adapter

  @doc """
  Converts an ExESDB EventRecord to a Commanded RecordedEvent.
  
  Uses the adapter's robust conversion logic that handles version conversion,
  metadata parsing, and various edge cases.
  """
  def convert_event(%ExESDB.Schema.EventRecord{} = event_record) do
    Adapter.convert_event_record(event_record)
  end

  def convert_event(%Commanded.EventStore.RecordedEvent{} = event), do: event

  @doc """
  Converts a list of events, handling both ExESDB and Commanded formats.
  
  Uses the adapter's batch conversion logic for optimal performance.
  """
  def convert_events(events) when is_list(events) do
    Adapter.convert_events(events)
  end
end