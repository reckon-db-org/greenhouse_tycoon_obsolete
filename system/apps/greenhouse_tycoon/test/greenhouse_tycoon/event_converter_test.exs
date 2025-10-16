defmodule GreenhouseTycoon.EventConverterTest do
  use ExUnit.Case, async: true
  
  alias GreenhouseTycoon.EventConverter
  alias ExESDB.Schema.EventRecord
  alias Commanded.EventStore.RecordedEvent

  describe "EventConverter using adapter v0.8.1 public API" do
    test "convert_event/1 converts ExESDB EventRecord to Commanded RecordedEvent" do
      # Create a sample ExESDB EventRecord
      event_record = %EventRecord{
        event_id: "test-event-123",
        event_number: 5,
        event_stream_id: "greenhouse-test",
        event_type: "GreenhouseTycoon.TestEvent",
        data: %{"greenhouse_id" => "gh-1", "value" => 25.5},
        metadata: %{
          correlation_id: "corr-123",
          causation_id: "cause-456"
        },
        created: ~U[2023-01-01 12:00:00Z]
      }

      # Call our EventConverter which uses the adapter's public API
      result = EventConverter.convert_event(event_record)

      # Verify the result is a Commanded RecordedEvent
      assert %RecordedEvent{} = result
      assert result.event_id == "test-event-123"
      assert result.event_number == 5
      assert result.stream_id == "greenhouse-test"
      assert result.event_type == "GreenhouseTycoon.TestEvent"
      assert result.data == %{"greenhouse_id" => "gh-1", "value" => 25.5}
      assert result.correlation_id == "corr-123"
      assert result.causation_id == "cause-456"
      # EventConverter uses event_number + 1 for stream_version (since metadata doesn't contain stream_version)
      assert result.stream_version == 6  # 5 + 1
      assert result.created_at == ~U[2023-01-01 12:00:00Z]
    end

    test "convert_event/1 passes through already converted RecordedEvents" do
      # Create a Commanded RecordedEvent (already converted)
      recorded_event = %RecordedEvent{
        event_id: "already-converted",
        event_number: 3,
        stream_id: "greenhouse-test",
        stream_version: 3,
        event_type: "AlreadyConverted",
        data: %{"already" => "converted"},
        metadata: %{},
        created_at: ~U[2023-01-01 12:00:00Z]
      }

      # Should pass through unchanged
      result = EventConverter.convert_event(recorded_event)
      assert result == recorded_event
    end

    test "convert_events/1 converts a list of events" do
      event_record1 = %EventRecord{
        event_id: "event-1",
        event_number: 1,
        event_stream_id: "greenhouse-test",
        event_type: "Event1",
        data: %{"event" => 1},
        metadata: %{correlation_id: "corr-1"},
        created: ~U[2023-01-01 12:00:00Z]
      }

      event_record2 = %EventRecord{
        event_id: "event-2", 
        event_number: 2,
        event_stream_id: "greenhouse-test",
        event_type: "Event2",
        data: %{"event" => 2},
        metadata: %{correlation_id: "corr-2"},
        created: ~U[2023-01-01 12:00:01Z]
      }

      events = [event_record1, event_record2]
      
      # Call the batch conversion function
      results = EventConverter.convert_events(events)

      # Verify the results
      assert length(results) == 2
      assert [%RecordedEvent{}, %RecordedEvent{}] = results
      
      [result1, result2] = results
      assert result1.event_id == "event-1"
      assert result1.stream_version == 2  # event_number 1 + 1
      assert result1.correlation_id == "corr-1"
      
      assert result2.event_id == "event-2"
      assert result2.stream_version == 3  # event_number 2 + 1
      assert result2.correlation_id == "corr-2"
    end

    test "convert_events/1 handles mixed event types (ExESDB + Commanded)" do
      event_record = %EventRecord{
        event_id: "esdb-event",
        event_number: 1,
        event_stream_id: "test-stream",
        event_type: "ExESDBEvent",
        data: %{"type" => "esdb"},
        metadata: %{},
        created: ~U[2023-01-01 12:00:00Z]
      }

      recorded_event = %RecordedEvent{
        event_id: "commanded-event",
        event_number: 2,
        stream_id: "test-stream",
        stream_version: 2,
        event_type: "CommandedEvent",
        data: %{"type" => "commanded"},
        metadata: %{},
        created_at: ~U[2023-01-01 12:00:01Z]
      }

      events = [event_record, recorded_event]
      
      # Call the batch conversion function
      results = EventConverter.convert_events(events)

      # Verify the results
      assert length(results) == 2
      assert [%RecordedEvent{}, %RecordedEvent{}] = results
      
      [result1, result2] = results
      assert result1.event_id == "esdb-event"
      assert result1.event_type == "ExESDBEvent"
      assert result1.stream_version == 2  # event_number 1 + 1
      
      assert result2.event_id == "commanded-event"
      assert result2.event_type == "CommandedEvent" 
      # Second event should be unchanged since it was already a RecordedEvent
      assert result2 == recorded_event
    end

    test "convert_event/1 handles events with complex metadata correctly" do
      # Test with nil metadata
      event_with_nil_metadata = %EventRecord{
        event_id: "nil-metadata",
        event_number: 1,
        event_stream_id: "test-stream",
        event_type: "TestEvent",
        data: %{},
        metadata: nil,
        created: ~U[2023-01-01 12:00:00Z]
      }

      result1 = EventConverter.convert_event(event_with_nil_metadata)
      assert result1.correlation_id == nil
      assert result1.causation_id == nil
      assert result1.stream_version == 2  # event_number 1 + 1

      # Test with empty metadata
      event_with_empty_metadata = %EventRecord{
        event_id: "empty-metadata",
        event_number: 3,
        event_stream_id: "test-stream", 
        event_type: "TestEvent",
        data: %{},
        metadata: %{},
        created: ~U[2023-01-01 12:00:00Z]
      }

      result2 = EventConverter.convert_event(event_with_empty_metadata)
      assert result2.correlation_id == nil
      assert result2.causation_id == nil
      assert result2.stream_version == 4  # event_number 3 + 1
    end
  end
end