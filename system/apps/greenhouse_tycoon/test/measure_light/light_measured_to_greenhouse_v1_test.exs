defmodule GreenhouseTycoon.MeasureLight.LightMeasuredToGreenhouseV1Test do
  use ExUnit.Case, async: false

  alias GreenhouseTycoon.MeasureLight.EventV1, as: LightMeasuredEvent
  alias GreenhouseTycoon.MeasureLight.LightMeasuredToGreenhouseV1
  alias GreenhouseTycoon.ReadModels.GreenhouseReadModel

  @cache_name :greenhouse_read_models
  @test_greenhouse_id "test-greenhouse-light-measure-123"

  setup do
    Cachex.clear(@cache_name)
    create_test_greenhouse()
    :ok
  end

  test "handles LightMeasured event and updates read model" do
    measured_at = DateTime.utc_now()
    event = %LightMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      light: 78.2,
      measured_at: measured_at
    }

    result = LightMeasuredToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.current_light == 78.2
    assert read_model.updated_at == measured_at
    assert read_model.event_count == 2
    assert read_model.target_light == 80.0
    assert read_model.name == "Test Greenhouse"
  end

  test "recalculates status after light update - warning" do
    event = %LightMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      light: 40.0,  # 40 lumens below target of 80.0
      measured_at: DateTime.utc_now()
    }

    LightMeasuredToGreenhouseV1.handle(event, %{})

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.status == :warning
    assert read_model.current_light == 40.0
  end

  test "maintains active status when light is within tolerance" do
    # First set current temperature to make greenhouse active
    {:ok, initial_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    active_model = %{initial_model | 
      current_temperature: 22.0,
      current_light: 80.0,
      status: :active
    }
    Cachex.put(@cache_name, @test_greenhouse_id, active_model)

    event = %LightMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      light: 75.0,  # 5 lumens from target, within tolerance (30)
      measured_at: DateTime.utc_now()
    }

    LightMeasuredToGreenhouseV1.handle(event, %{})

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.status == :active
    assert read_model.current_light == 75.0
  end

  test "returns error when greenhouse not found in cache" do
    event = %LightMeasuredEvent{
      greenhouse_id: "non-existent-greenhouse",
      light: 80.0,
      measured_at: DateTime.utc_now()
    }

    result = LightMeasuredToGreenhouseV1.handle(event, %{})

    assert result == {:error, :greenhouse_not_found}
  end

  test "returns error when cache is not available" do
    cache_pid = Process.whereis(@cache_name)
    Process.exit(cache_pid, :kill)
    :timer.sleep(10)

    event = %LightMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      light: 80.0,
      measured_at: DateTime.utc_now()
    }

    result = LightMeasuredToGreenhouseV1.handle(event, %{})

    assert result == {:error, :cache_not_available}

    {:ok, _} = Cachex.start_link(@cache_name)
  end

  test "handles zero light measurement" do
    event = %LightMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      light: 0.0,
      measured_at: DateTime.utc_now()
    }

    result = LightMeasuredToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.current_light == 0.0
    assert read_model.status == :inactive
  end

  test "handles high light measurement" do
    event = %LightMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      light: 150.0,
      measured_at: DateTime.utc_now()
    }

    result = LightMeasuredToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.current_light == 150.0
    # 70 lumens from target of 80.0, beyond 30 lumen threshold
    assert read_model.status == :warning
  end

  test "correctly identifies warning status at threshold boundaries" do
    target_light = 80.0
    warning_light = target_light - 30.1  # Just beyond threshold

    event = %LightMeasuredEvent{
      greenhouse_id: @test_greenhouse_id,
      light: warning_light,
      measured_at: DateTime.utc_now()
    }

    LightMeasuredToGreenhouseV1.handle(event, %{})

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
      target_light: 80.0,
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
