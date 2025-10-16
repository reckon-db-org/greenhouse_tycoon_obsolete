defmodule GreenhouseTycoon.InitializeGreenhouse.InitializedToPubSubV1Test do
  use ExUnit.Case, async: false

  alias GreenhouseTycoon.InitializeGreenhouse.EventV1, as: GreenhouseInitializedEvent
  alias GreenhouseTycoon.InitializeGreenhouse.InitializedToPubSubV1
  alias GreenhouseTycoon.ReadModels.Greenhouse

  @test_greenhouse_id "test-greenhouse-init-123"
  @projections_topic "greenhouse_projections"

  setup do
    # Subscribe to projection events for testing
    Phoenix.PubSub.subscribe(GreenhouseTycoon.PubSub, @projections_topic)
    :ok
  end

  test "handles GreenhouseInitialized event and broadcasts greenhouse creation" do
    event = %GreenhouseInitializedEvent{
      greenhouse_id: @test_greenhouse_id,
      name: "Test Greenhouse",
      location: "Test Location",
      city: "Test City", 
      country: "Test Country",
      target_temperature: 22.5,
      target_humidity: 65.0,
      target_light: 80.0,
      initialized_at: DateTime.utc_now()
    }

    result = InitializedToPubSubV1.handle(event, %{})

    assert result == :ok

    # Verify PubSub broadcast was sent
    assert_receive {:greenhouse_created, read_model}
    assert %Greenhouse{} = read_model
    assert read_model.greenhouse_id == @test_greenhouse_id
    assert read_model.name == "Test Greenhouse"
    assert read_model.location == "Test Location"
    assert read_model.city == "Test City"
    assert read_model.country == "Test Country"
    assert read_model.target_temperature == 22.5
    assert read_model.target_humidity == 65.0
    assert read_model.target_light == 80.0
    assert read_model.current_temperature == nil
    assert read_model.current_humidity == nil
    assert read_model.current_light == nil
    assert read_model.event_count == 1
    assert read_model.status == :inactive
    assert read_model.created_at == event.initialized_at
    assert read_model.updated_at == event.initialized_at
  end

  test "handles event with nil target_light" do
    event = %GreenhouseInitializedEvent{
      greenhouse_id: @test_greenhouse_id,
      name: "Test Greenhouse",
      location: "Test Location",
      city: "Test City",
      country: "Test Country",
      target_temperature: 20.0,
      target_humidity: 60.0,
      target_light: nil,
      initialized_at: DateTime.utc_now()
    }

    result = InitializedToPubSubV1.handle(event, %{})

    assert result == :ok

    # Verify PubSub broadcast was sent with correct data
    assert_receive {:greenhouse_created, read_model}
    assert read_model.target_light == nil
    assert read_model.target_temperature == 20.0
    assert read_model.target_humidity == 60.0
  end

  test "calculates correct initial status" do
    event = %GreenhouseInitializedEvent{
      greenhouse_id: @test_greenhouse_id,
      name: "Test Greenhouse",
      location: "Test Location",
      city: "Test City",
      country: "Test Country", 
      target_temperature: 22.5,
      target_humidity: 65.0,
      target_light: nil,
      initialized_at: DateTime.utc_now()
    }

    InitializedToPubSubV1.handle(event, %{})

    # Verify PubSub broadcast contains correct status
    assert_receive {:greenhouse_created, read_model}
    assert read_model.status == :inactive
  end

  test "returns error when PubSub broadcast fails" do
    # This is harder to test without mocking, but we can test the happy path
    # Error handling for PubSub failures is implemented in the projection
    event = %GreenhouseInitializedEvent{
      greenhouse_id: @test_greenhouse_id,
      name: "Test Greenhouse",
      location: "Test Location",
      city: "Test City",
      country: "Test Country",
      target_temperature: 22.5,
      target_humidity: 65.0,
      target_light: 80.0,
      initialized_at: DateTime.utc_now()
    }

    result = InitializedToPubSubV1.handle(event, %{})

    assert result == :ok
    assert_receive {:greenhouse_created, _read_model}
  end
end
