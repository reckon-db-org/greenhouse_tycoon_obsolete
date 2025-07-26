defmodule GreenhouseTycoon.MeasureHumidity.HumidityMeasuredToGreenhouseV1Test do
  use ExUnit.Case, async: false

  alias GreenhouseTycoon.MeasureHumidity.EventV1, as: HumidityMeasuredEvent
  alias GreenhouseTycoon.MeasureHumidity.HumidityMeasuredToGreenhouseV1
  alias GreenhouseTycoon.ReadModels.GreenhouseReadModel

  @cache_name :greenhouse_read_models
  @test_greenhouse_id "test-greenhouse-humidity-measure-123"

  setup do
    Cachex.clear(@cache_name)
    create_test_greenhouse()
    :ok
  end

  test "handles HumidityMeasured event and updates read model" do
    measured_at = DateTime.utc_now()
    event = %HumidityMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      humidity: 72.3,
      measured_at: measured_at
    }

    result = HumidityMeasuredToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.current_humidity == 72.3
    assert read_model.updated_at == measured_at
    assert read_model.event_count == 2
    assert read_model.target_humidity == 65.0
    assert read_model.name == "Test Greenhouse"
  end

  test "recalculates status after humidity update - warning" do
    event = %HumidityMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      humidity: 30.0,  # 35% below target of 65.0
      measured_at: DateTime.utc_now()
    }

    HumidityMeasuredToGreenhouseV1.handle(event, %{})

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.status == :warning
    assert read_model.current_humidity == 30.0
  end

  test "maintains active status when humidity is within tolerance" do
    # First set current temperature to make greenhouse active
    {:ok, initial_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    active_model = %{initial_model | 
      current_temperature: 22.0,
      current_humidity: 65.0,
      status: :active
    }
    Cachex.put(@cache_name, @test_greenhouse_id, active_model)

    event = %HumidityMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      humidity: 68.0,  # 3% from target, within tolerance
      measured_at: DateTime.utc_now()
    }

    HumidityMeasuredToGreenhouseV1.handle(event, %{})

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.status == :active
    assert read_model.current_humidity == 68.0
  end

  test "returns error when greenhouse not found in cache" do
    event = %HumidityMeasuredEvent{
      greenhouse_id: "non-existent-greenhouse",
      humidity: 70.0,
      measured_at: DateTime.utc_now()
    }

    result = HumidityMeasuredToGreenhouseV1.handle(event, %{})

    assert result == {:error, :greenhouse_not_found}
  end

  test "returns error when cache is not available" do
    cache_pid = Process.whereis(@cache_name)
    Process.exit(cache_pid, :kill)
    :timer.sleep(10)

    event = %HumidityMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      humidity: 70.0,
      measured_at: DateTime.utc_now()
    }

    result = HumidityMeasuredToGreenhouseV1.handle(event, %{})

    assert result == {:error, :cache_not_available}

    {:ok, _} = Cachex.start_link(@cache_name)
  end

  test "handles zero humidity measurement" do
    event = %HumidityMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      humidity: 0.0,
      measured_at: DateTime.utc_now()
    }

    result = HumidityMeasuredToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.current_humidity == 0.0
    assert read_model.status == :inactive
  end

  test "handles maximum humidity measurement" do
    event = %HumidityMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      humidity: 100.0,
      measured_at: DateTime.utc_now()
    }

    result = HumidityMeasuredToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.current_humidity == 100.0
    assert read_model.status == :warning
  end

  test "correctly identifies warning status at threshold boundaries" do
    target_humidity = 65.0
    warning_humidity = target_humidity - 20.1  # Just beyond threshold

    event = %HumidityMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      humidity: warning_humidity,
      measured_at: DateTime.utc_now()
    }

    HumidityMeasuredToGreenhouseV1.handle(event, %{})

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.status == :warning
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
