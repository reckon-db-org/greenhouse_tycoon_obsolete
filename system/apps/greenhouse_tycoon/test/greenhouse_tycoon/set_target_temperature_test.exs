defmodule GreenhouseTycoon.SetTargetTemperatureTest do
  use ExUnit.Case, async: false

  alias GreenhouseTycoon.{Greenhouse, API}
  alias GreenhouseTycoon.SetTargetTemperature.CommandV1, as: SetTargetTemperatureCommand

  @greenhouse_id "test-set-temperature-greenhouse"
  @test_name "Test SetTargetTemperature Greenhouse"
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

  describe "SetTargetTemperature slice" do
    test "sets temperature successfully" do
      {:ok, command} = SetTargetTemperatureCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_temperature: 24.5,
        set_by: "test_user"
      })

      # Execute command through the aggregate
      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id, target_temperature: 20.0}
      {:ok, [event]} = GreenhouseTycoon.SetTargetTemperature.MaybeSetTargetTemperatureV1.execute(greenhouse, command)

      assert event.greenhouse_id == @greenhouse_id
      assert event.target_temperature == 24.5
      assert event.set_by == "test_user"
      assert event.previous_target_temperature == 20.0
    end

    test "rejects invalid temperature values - too high" do
      {:ok, command} = SetTargetTemperatureCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_temperature: 100.0,  # Invalid: > 80°C
        set_by: "test_user"
      })

      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      result = GreenhouseTycoon.SetTargetTemperature.MaybeSetTargetTemperatureV1.execute(greenhouse, command)

      assert {:error, :invalid_target_temperature} = result
    end

    test "rejects invalid temperature values - too low" do
      {:ok, command} = SetTargetTemperatureCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_temperature: -60.0,  # Invalid: < -50°C
        set_by: "test_user"
      })

      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      result = GreenhouseTycoon.SetTargetTemperature.MaybeSetTargetTemperatureV1.execute(greenhouse, command)

      assert {:error, :invalid_target_temperature} = result
    end

    test "rejects command for non-existent greenhouse" do
      {:ok, command} = SetTargetTemperatureCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_temperature: 22.0,
        set_by: "test_user"
      })

      # Greenhouse with nil ID (not initialized)
      greenhouse = %Greenhouse{greenhouse_id: nil}
      result = GreenhouseTycoon.SetTargetTemperature.MaybeSetTargetTemperatureV1.execute(greenhouse, command)

      assert {:error, :greenhouse_not_found} = result
    end
  end

  describe "Aggregate event handlers" do
    test "SetTargetTemperature event updates aggregate state" do
      event = %GreenhouseTycoon.SetTargetTemperature.EventV1{
        greenhouse_id: @greenhouse_id,
        target_temperature: 23.5,
        previous_target_temperature: 20.0,
        set_by: "test_user",
        set_at: DateTime.utc_now(),
        version: 1
      }

      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      updated_greenhouse = GreenhouseTycoon.SetTargetTemperature.TargetTemperatureSetToAggregateV1.apply(greenhouse, event)

      assert updated_greenhouse.target_temperature == 23.5
      assert updated_greenhouse.updated_at == event.set_at
    end
  end
end
