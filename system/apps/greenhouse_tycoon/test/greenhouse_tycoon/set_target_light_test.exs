defmodule GreenhouseTycoon.SetTargetLightTest do
  use ExUnit.Case, async: false

  alias GreenhouseTycoon.{Greenhouse, API}
  alias GreenhouseTycoon.SetTargetLight.CommandV1, as: SetTargetLightCommand

  @greenhouse_id "test-set-light-greenhouse"
  @test_name "Test SetTargetLight Greenhouse"
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

  describe "SetTargetLight slice" do
    test "sets light successfully" do
      {:ok, command} = SetTargetLightCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_light: 1500.0,
        set_by: "test_user"
      })

      # Execute command through the aggregate
      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id, target_light: 1000.0}
      {:ok, [event]} = GreenhouseTycoon.SetTargetLight.MaybeSetTargetLightV1.execute(greenhouse, command)

      assert event.greenhouse_id == @greenhouse_id
      assert event.target_light == 1500.0
      assert event.set_by == "test_user"
      assert event.previous_target_light == 1000.0
    end

    test "rejects invalid light values - too high" do
      {:ok, command} = SetTargetLightCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_light: 150_000.0,  # Invalid: > 100,000 lumens
        set_by: "test_user"
      })

      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      result = GreenhouseTycoon.SetTargetLight.MaybeSetTargetLightV1.execute(greenhouse, command)

      assert {:error, :invalid_target_light} = result
    end

    test "rejects invalid light values - negative" do
      {:ok, command} = SetTargetLightCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_light: -100.0,  # Invalid: negative
        set_by: "test_user"
      })

      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      result = GreenhouseTycoon.SetTargetLight.MaybeSetTargetLightV1.execute(greenhouse, command)

      assert {:error, :invalid_target_light} = result
    end

    test "rejects command for non-existent greenhouse" do
      {:ok, command} = SetTargetLightCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_light: 800.0,
        set_by: "test_user"
      })

      # Greenhouse with nil ID (not initialized)
      greenhouse = %Greenhouse{greenhouse_id: nil}
      result = GreenhouseTycoon.SetTargetLight.MaybeSetTargetLightV1.execute(greenhouse, command)

      assert {:error, :greenhouse_not_found} = result
    end
  end

  describe "Aggregate event handlers" do
    test "SetTargetLight event updates aggregate state" do
      event = %GreenhouseTycoon.SetTargetLight.EventV1{
        greenhouse_id: @greenhouse_id,
        target_light: 1200.0,
        previous_target_light: 800.0,
        set_by: "test_user",
        set_at: DateTime.utc_now()
      }

      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      updated_greenhouse = GreenhouseTycoon.SetTargetLight.TargetLightSetToAggregateV1.apply(greenhouse, event)

      assert updated_greenhouse.target_light == 1200.0
      assert updated_greenhouse.updated_at == event.set_at
    end
  end
end
