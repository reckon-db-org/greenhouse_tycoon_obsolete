defmodule GreenhouseTycoon.MeasureTemperature.TemperatureMeasuredToGreenhouseV1Test do
  use ExUnit.Case, async: false

  alias GreenhouseTycoon.MeasureTemperature.EventV1, as: TemperatureMeasuredEvent
  alias GreenhouseTycoon.MeasureTemperature.TemperatureMeasuredToGreenhouseV1
  alias GreenhouseTycoon.ReadModels.GreenhouseReadModel

  @cache_name :greenhouse_read_models
  @test_greenhouse_id "test-greenhouse-temp-measure-123"

  setup do
    Cachex.clear(@cache_name)
    create_test_greenhouse()
    :ok
  end

  test "handles TemperatureMeasured event and updates read model" do
    measured_at = DateTime.utc_now()
    event = %TemperatureMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      temperature: 24.2,
      measured_at: measured_at
    }

    result = TemperatureMeasuredToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.current_temperature == 24.2
    assert read_model.updated_at == measured_at
    assert read_model.event_count == 2
    assert read_model.target_temperature == 22.0
    assert read_model.name == "Test Greenhouse"
  end

  test "recalculates status after temperature update - warning" do
    event = %TemperatureMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      temperature: 35.0,  # 13 degrees above target of 22.0
      measured_at: DateTime.utc_now()
    }

    TemperatureMeasuredToGreenhouseV1.handle(event, %{})

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.status == :warning
    assert read_model.current_temperature == 35.0
  end

  test "maintains active status when temperature is within tolerance" do
    # First set current humidity to make greenhouse active
    {:ok, initial_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    active_model = %{initial_model | 
      current_humidity: 65.0,
      current_temperature: 22.0,
      status: :active
    }
    Cachex.put(@cache_name, @test_greenhouse_id, active_model)

    event = %TemperatureMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      temperature: 23.0,  # 1 degree from target, within tolerance
      measured_at: DateTime.utc_now()
    }

    TemperatureMeasuredToGreenhouseV1.handle(event, %{})

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.status == :active
    assert read_model.current_temperature == 23.0
  end

  test "returns error when greenhouse not found in cache" do
    event = %TemperatureMeasuredEvent{
      greenhouse_id: "non-existent-greenhouse",
      temperature: 20.0,
      measured_at: DateTime.utc_now()
    }

    result = TemperatureMeasuredToGreenhouseV1.handle(event, %{})

    assert result == {:error, :greenhouse_not_found}
  end

  test "returns error when cache is not available" do
    cache_pid = Process.whereis(@cache_name)
    Process.exit(cache_pid, :kill)
    :timer.sleep(10)

    event = %TemperatureMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      temperature: 20.0,
      measured_at: DateTime.utc_now()
    }

    result = TemperatureMeasuredToGreenhouseV1.handle(event, %{})

    assert result == {:error, :cache_not_available}

    {:ok, _} = Cachex.start_link(@cache_name)
  end

  test "handles zero temperature measurement" do
    event = %TemperatureMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      temperature: 0.0,
      measured_at: DateTime.utc_now()
    }

    result = TemperatureMeasuredToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.current_temperature == 0.0
    assert read_model.status == :inactive
  end

  test "handles negative temperature measurement" do
    event = %TemperatureMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      temperature: -10.5,
      measured_at: DateTime.utc_now()
    }

    result = TemperatureMeasuredToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.current_temperature == -10.5
    assert read_model.status == :warning
  end

  test "handles multiple measurements in sequence" do
    measurements = [20.0, 21.5, 23.0, 22.2]

    Enum.each(measurements, fn temp ->
      event = %TemperatureMeasuredEvent{
        greenhouse_id: @test_greenhouse_id,
        temperature: temp,
        measured_at: DateTime.utc_now()
      }

      result = TemperatureMeasuredToGreenhouseV1.handle(event, %{})
      assert result == :ok
    end)

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.current_temperature == 22.2
    assert read_model.event_count == 5  # initial + 4 measurements
    assert read_model.status == :active
  end

  defp create_test_greenhouse do
    read_model = %GreenhouseReadModel{
      greenhouse_id: @test_greenhouse_id,
      name: "Test Greenhouse",
      location: "Test Location",
      city: "Test City",
      country: "Test Country",
      target_temperature: 22.0,
      target_humidity: 65.0,
      target_light: nil,
      current_temperature: nil,
      current_humidity: nil,
      current_light: nil,
      event_count: 1,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      status: :inactive
    }

    Cachex.put(@cache_name, @test_greenhouse_id, read_model)
  end
end
