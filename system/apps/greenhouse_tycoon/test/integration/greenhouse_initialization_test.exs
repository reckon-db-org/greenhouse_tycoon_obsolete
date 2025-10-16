defmodule GreenhouseTycoon.Integration.GreenhouseInitializationTest do
  use ExUnit.Case, async: false
  
  import Ecto.Query
  
  alias GreenhouseTycoon.{API, Repo, Greenhouse}
  alias GreenhouseTycoon.InitializeGreenhouse.EventV1, as: GreenhouseInitialized
  alias GreenhouseTycoon.TestSupport.EventListener
  setup do
    # Clean up database for fresh state
    GreenhouseTycoon.Repo.delete_all(Greenhouse)
    
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
        
        {:error, :timeout, event_type} ->
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

    test "initialized event should trigger database projection within timeout" do
      greenhouse_id = "test_projection_#{System.unique_integer([:positive])}"
      
      # WHEN: Initialize a greenhouse
      assert :ok = API.create_greenhouse(
        greenhouse_id,
        "Test Projection Greenhouse",
        "51.0,5.0", 
        "Projection City",
        "Projection Country"
      )
      
      # THEN: Wait for projection to process and update database
      assert_eventually(fn ->
        greenhouses = GreenhouseTycoon.Repo.all(Greenhouse)
        greenhouse = Enum.find(greenhouses, &(&1.greenhouse_id == greenhouse_id))
        
        assert greenhouse != nil, "Greenhouse should be created in database via projection"
        assert greenhouse.name == "Test Projection Greenhouse"
        assert greenhouse.location == "51.0,5.0"
        assert greenhouse.city == "Projection City"
        assert greenhouse.country == "Projection Country"
      end, 10_000, 500)
    end

    test "projection should handle multiple greenhouse initializations" do
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
      
      # THEN: All should be projected to database
      assert_eventually(fn ->
        greenhouses = GreenhouseTycoon.Repo.all(Greenhouse)
        found_ids = Enum.map(greenhouses, & &1.greenhouse_id)
        
        for greenhouse_id <- greenhouse_ids do
          assert greenhouse_id in found_ids, 
            "Expected greenhouse #{greenhouse_id} to be in database, found: #{inspect(found_ids)}"
        end
        
        assert length(greenhouses) >= 3, "Should have at least 3 greenhouses in database"
      end, 15_000, 500)
    end
  end

  # Helper functions

  defp get_events_for_stream(stream_id) do
    # Direct query to event store to verify event persistence
    # This will help us understand if the issue is with event storage or projection
    try do
      case ExESDB.API.stream_events(:greenhouse_tycoon, stream_id, 0, 1000, :forward) do
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

  defp assert_eventually(assertion_fun, timeout_ms \\ 5_000, interval_ms \\ 100) do
    end_time = System.monotonic_time(:millisecond) + timeout_ms
    assert_eventually_loop(assertion_fun, end_time, interval_ms)
  end

  defp assert_eventually_loop(assertion_fun, end_time, interval_ms) do
    try do
      assertion_fun.()
    rescue
      error in [ExUnit.AssertionError] ->
        if System.monotonic_time(:millisecond) >= end_time do
          reraise error, __STACKTRACE__
        else
          Process.sleep(interval_ms)
          assert_eventually_loop(assertion_fun, end_time, interval_ms)
        end
    end
  end
end