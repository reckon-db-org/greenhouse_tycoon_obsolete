defmodule GreenhouseTycoon.SetTargetHumidityTest do
  use ExUnit.Case, async: false

  alias GreenhouseTycoon.{Greenhouse, API}
  alias GreenhouseTycoon.SetTargetHumidity.CommandV1, as: SetTargetHumidityCommand

  @greenhouse_id "test-set-humidity-greenhouse"
  @test_name "Test SetTargetHumidity Greenhouse"
  @test_location "Test Location"
  @test_city "Sydney"
  @test_country "Australia"

  setup do
    # Clean up any existing greenhouse state
    API.reset_greenhouse(@greenhouse_id)
    
    # Initialize greenhouse for testing
    :ok = API.initialize_greenhouse(
      @greenhouse_id,
      @test_name,
      @test_location,
      @test_city,
      @test_country
    )

    :ok
  end

  describe "SetTargetHumidity slice" do
    test "sets humidity successfully" do
      {:ok, command} = SetTargetHumidityCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_humidity: 65.5,
        set_by: "test_user"
      })

      # Execute command through the aggregate
      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id, target_humidity: 50.0}
      {:ok, [event]} = GreenhouseTycoon.SetTargetHumidity.MaybeSetTargetHumidityV1.execute(greenhouse, command)

      assert event.greenhouse_id == @greenhouse_id
      assert event.target_humidity == 65.5
      assert event.set_by == "test_user"
      assert event.previous_target_humidity == 50.0
    end

    test "rejects invalid humidity values - too high" do
      {:ok, command} = SetTargetHumidityCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_humidity: 110.0,  # Invalid: > 100%
        set_by: "test_user"
      })

      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      result = GreenhouseTycoon.SetTargetHumidity.MaybeSetTargetHumidityV1.execute(greenhouse, command)

      assert {:error, :invalid_target_humidity} = result
    end

    test "rejects invalid humidity values - negative" do
      {:ok, command} = SetTargetHumidityCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_humidity: -5.0,  # Invalid: negative
        set_by: "test_user"
      })

      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      result = GreenhouseTycoon.SetTargetHumidity.MaybeSetTargetHumidityV1.execute(greenhouse, command)

      assert {:error, :invalid_target_humidity} = result
    end

    test "rejects command for non-existent greenhouse" do
      {:ok, command} = SetTargetHumidityCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_humidity: 60.0,
        set_by: "test_user"
      })

      # Greenhouse with nil ID (not initialized)
      greenhouse = %Greenhouse{greenhouse_id: nil}
      result = GreenhouseTycoon.SetTargetHumidity.MaybeSetTargetHumidityV1.execute(greenhouse, command)

      assert {:error, :greenhouse_not_found} = result
    end
  end

  describe "Aggregate event handlers" do
    test "SetTargetHumidity event updates aggregate state" do
      event = %GreenhouseTycoon.SetTargetHumidity.EventV1{
        greenhouse_id: @greenhouse_id,
        target_humidity: 70.0,
        previous_target_humidity: 50.0,
        set_by: "test_user",
        set_at: DateTime.utc_now()
      }

      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      updated_greenhouse = GreenhouseTycoon.SetTargetHumidity.TargetHumiditySetToAggregateV1.apply(greenhouse, event)

      assert updated_greenhouse.target_humidity == 70.0
      assert updated_greenhouse.updated_at == event.set_at
    end
  end
end
