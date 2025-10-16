defmodule GreenhouseTycoon.Integration.GreenhouseEventFlowTest do
  use ExUnit.Case, async: false
  
  alias GreenhouseTycoon.API
  alias GreenhouseTycoon.InitializeGreenhouse.EventV1, as: GreenhouseInitialized
  alias GreenhouseTycoon.TestSupport.EventListener

  @moduledoc """
  Integration tests verifying that greenhouse initialization commands
  properly trigger event creation and flow through the system.
  """
  
  setup do
    # Start event listener if not already started
    case GenServer.whereis(EventListener) do
      nil -> {:ok, _pid} = EventListener.start_link()
      _pid -> :ok
    end
    
    # Clear any previous events
    EventListener.clear_events()
    
    # Subscribe to all events to capture what's being published (fallback)
    Phoenix.PubSub.subscribe(GreenhouseTycoon.PubSub, "greenhouse_events")
    
    :ok
  end

  describe "greenhouse initialization event flow" do
    test "GIVEN a running greenhouse application, WHEN initializing a greenhouse, THEN the initialized event is received" do
      greenhouse_id = "test_event_flow_#{System.unique_integer([:positive])}"
      
      # WHEN: Initialize a greenhouse via API
      assert :ok = API.create_greenhouse(
        greenhouse_id,
        "Test Event Flow Greenhouse", 
        "50.0,4.0",
        "Test City",
        "Test Country",
        20.0,
        60.0
      )
      
      # THEN: Verify the event was published and received via EventListener
      case EventListener.wait_for_event(:greenhouse_initialized, 5_000) do
        {:ok, event} ->
          assert event.source == :ex_esdb
          assert event.type == "greenhouse_initialized:v1"
          assert event.data.greenhouse_id == greenhouse_id
          assert event.data.name == "Test Event Flow Greenhouse"
          assert event.data.location == "50.0,4.0"
          assert event.data.city == "Test City"
          assert event.data.country == "Test Country"
          assert event.data.target_temperature == 20.0
          assert event.data.target_humidity == 60.0
        
        {:error, :timeout, _event_type} ->
          # Fallback: try to receive via direct PubSub subscription
          assert_receive {:greenhouse_initialized, %GreenhouseInitialized{} = fallback_event}, 1_000
          
          assert fallback_event.greenhouse_id == greenhouse_id
          assert fallback_event.name == "Test Event Flow Greenhouse"
          assert fallback_event.location == "50.0,4.0"
          assert fallback_event.city == "Test City"
          assert fallback_event.country == "Test Country"
          assert fallback_event.target_temperature == 20.0
          assert fallback_event.target_humidity == 60.0
      end
      
      # Additional verification: Check if event reached the event store
      # We can query the event store directly to verify persistence
      events = get_events_for_stream("greenhouse_tycoon_#{greenhouse_id}")
      
      assert length(events) == 1
      [stored_event] = events
      assert stored_event.event_type == "greenhouse_initialized:v1"
      assert stored_event.data.greenhouse_id == greenhouse_id
    end

    test "multiple greenhouse initializations should create multiple events" do
      greenhouse_ids = for i <- 1..3, do: "test_multi_#{i}_#{System.unique_integer([:positive])}"
      
      # WHEN: Initialize multiple greenhouses
      for {id, index} <- Enum.with_index(greenhouse_ids, 1) do
        assert :ok = API.create_greenhouse(
          id,
          "Multi Test #{index}",
          "#{50 + index}.0,#{4 + index}.0",
          "City #{index}",
          "Country #{index}"
        )
      end
      
      # THEN: All should generate events and be captured by our event listener
      # Wait a moment for all events to be processed
      Process.sleep(2_000)
      
      all_events = EventListener.get_events()
      greenhouse_events = Enum.filter(all_events, fn event ->
        event.type == "greenhouse_initialized:v1" and
        event.data.greenhouse_id in greenhouse_ids
      end)
      
      assert length(greenhouse_events) >= 3, 
        "Expected at least 3 greenhouse events, got #{length(greenhouse_events)} events: #{inspect(Enum.map(greenhouse_events, & &1.data.greenhouse_id))}"
      
      # Verify each greenhouse has the expected data
      for {greenhouse_id, index} <- Enum.with_index(greenhouse_ids, 1) do
        matching_event = Enum.find(greenhouse_events, fn event ->
          event.data.greenhouse_id == greenhouse_id
        end)
        
        assert matching_event != nil, "Missing event for greenhouse #{greenhouse_id}"
        assert matching_event.data.name == "Multi Test #{index}"
        assert matching_event.data.city == "City #{index}"
        assert matching_event.data.country == "Country #{index}"
      end
    end
  end

  # Helper functions

  defp get_events_for_stream(stream_id) do
    # Direct query to event store to verify event persistence
    # This will help us understand if the issue is with event storage or projection
    try do
      case ExESDB.API.stream_events(:greenhouse_tycoon_test, stream_id, 0, 1000, :forward) do
        {:ok, events} -> events
        {:error, :stream_not_found} -> []
        {:error, reason} -> 
          flunk("Failed to read events from stream #{stream_id}: #{inspect(reason)}")
      end
    rescue
      error ->
        flunk("Error reading events: #{inspect(error)}")
    end
  end
end