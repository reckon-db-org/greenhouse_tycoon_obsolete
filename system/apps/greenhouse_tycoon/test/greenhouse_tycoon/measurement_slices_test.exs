defmodule GreenhouseTycoon.MeasurementSlicesTest do
  use ExUnit.Case, async: false

  alias GreenhouseTycoon.{Greenhouse, API}
  alias GreenhouseTycoon.MeasureHumidity.CommandV1, as: MeasureHumidityCommand
  alias GreenhouseTycoon.MeasureLight.CommandV1, as: MeasureLightCommand
  alias GreenhouseTycoon.MeasureTemperature.CommandV1, as: MeasureTemperatureCommand

  @greenhouse_id "test-measure-greenhouse"
  @test_name "Test Measurement Greenhouse"
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

  describe "MeasureHumidity slice" do
    test "measures humidity successfully" do
      now = DateTime.utc_now()
      
      {:ok, command} = MeasureHumidityCommand.new(%{
        greenhouse_id: @greenhouse_id,
        humidity: 65.5,
        measured_at: now
      })

      # Execute command through the aggregate
      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      {:ok, [event]} = GreenhouseTycoon.MeasureHumidity.MaybeMeasureHumidityV1.execute(greenhouse, command)

      assert event.greenhouse_id == @greenhouse_id
      assert event.humidity == 65.5
      assert event.measured_at == now
    end

    test "rejects invalid humidity values" do
      now = DateTime.utc_now()
      
      {:ok, command} = MeasureHumidityCommand.new(%{
        greenhouse_id: @greenhouse_id,
        humidity: 105.0,  # Invalid: > 100%
        measured_at: now
      })

      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      result = GreenhouseTycoon.MeasureHumidity.MaybeMeasureHumidityV1.execute(greenhouse, command)

      assert {:error, :invalid_humidity_range} = result
    end

    test "rejects negative humidity values" do
      now = DateTime.utc_now()
      
      {:ok, command} = MeasureHumidityCommand.new(%{
        greenhouse_id: @greenhouse_id,
        humidity: -5.0,  # Invalid: negative
        measured_at: now
      })

      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      result = GreenhouseTycoon.MeasureHumidity.MaybeMeasureHumidityV1.execute(greenhouse, command)

      assert {:error, :invalid_humidity_range} = result
    end
  end

  describe "MeasureLight slice" do
    test "measures light successfully" do
      now = DateTime.utc_now()
      
      {:ok, command} = MeasureLightCommand.new(%{
        greenhouse_id: @greenhouse_id,
        light: 1200.5,
        measured_at: now
      })

      # Execute command through the aggregate
      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      {:ok, [event]} = GreenhouseTycoon.MeasureLight.MaybeMeasureLightV1.execute(greenhouse, command)

      assert event.greenhouse_id == @greenhouse_id
      assert event.light == 1200.5
      assert event.measured_at == now
    end

    test "rejects negative light values" do
      now = DateTime.utc_now()
      
      {:ok, command} = MeasureLightCommand.new(%{
        greenhouse_id: @greenhouse_id,
        light: -100.0,  # Invalid: negative
        measured_at: now
      })

      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      result = GreenhouseTycoon.MeasureLight.MaybeMeasureLightV1.execute(greenhouse, command)

      assert {:error, :invalid_light_value} = result
    end
  end

  describe "MeasureTemperature slice" do
    test "measures temperature successfully" do
      now = DateTime.utc_now()

      {:ok, command} = MeasureTemperatureCommand.new(%{
        greenhouse_id: @greenhouse_id,
        temperature: 22.5,
        measured_at: now
      })

      # Execute command through the aggregate
      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      {:ok, [event]} = GreenhouseTycoon.MeasureTemperature.MaybeMeasureTemperatureV1.execute(greenhouse, command)

      assert event.greenhouse_id == @greenhouse_id
      assert event.temperature == 22.5
      assert event.measured_at == now
    end

    test "rejects invalid temperature values" do
      now = DateTime.utc_now()

      {:ok, command} = MeasureTemperatureCommand.new(%{
        greenhouse_id: @greenhouse_id,
        temperature: -150.0,  # Invalid: below -100°C
        measured_at: now
      })

      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      result = GreenhouseTycoon.MeasureTemperature.MaybeMeasureTemperatureV1.execute(greenhouse, command)

      assert {:error, :invalid_temperature} = result
    end
  end

  describe "Aggregate event handlers" do
    test "MeasureHumidity event updates aggregate state" do
      now = DateTime.utc_now()
      
      event = %GreenhouseTycoon.MeasureHumidity.EventV1{
        greenhouse_id: @greenhouse_id,
        humidity: 75.0,
        measured_at: now
      }

      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      updated_greenhouse = GreenhouseTycoon.MeasureHumidity.HumidityMeasuredToAggregateV1.apply(greenhouse, event)

      assert updated_greenhouse.current_humidity == 75.0
      assert updated_greenhouse.updated_at == now
    end

    test "MeasureLight event updates aggregate state" do
      now = DateTime.utc_now()
      
      event = %GreenhouseTycoon.MeasureLight.EventV1{
        greenhouse_id: @greenhouse_id,
        light: 800.0,
        measured_at: now
      }

      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      updated_greenhouse = GreenhouseTycoon.MeasureLight.LightMeasuredToAggregateV1.apply(greenhouse, event)

      assert updated_greenhouse.current_light == 800.0
      assert updated_greenhouse.updated_at == now
    end

    test "MeasureTemperature event updates aggregate state" do
      now = DateTime.utc_now()
      
      event = %GreenhouseTycoon.MeasureTemperature.EventV1{
        greenhouse_id: @greenhouse_id,
        temperature: 25.5,
        measured_at: now
      }

      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      updated_greenhouse = GreenhouseTycoon.MeasureTemperature.TemperatureMeasuredToAggregateV1.apply(greenhouse, event)

      assert updated_greenhouse.current_temperature == 25.5
      assert updated_greenhouse.updated_at == now
    end
  end
end
