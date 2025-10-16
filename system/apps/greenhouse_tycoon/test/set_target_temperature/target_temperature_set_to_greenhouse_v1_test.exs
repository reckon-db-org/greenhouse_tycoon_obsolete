defmodule GreenhouseTycoon.SetTargetTemperature.TargetTemperatureSetToGreenhouseV1Test do
  use ExUnit.Case, async: false

  alias GreenhouseTycoon.SetTargetTemperature.EventV1, as: TargetTemperatureSetEvent
  alias GreenhouseTycoon.SetTargetTemperature.TargetTemperatureSetToGreenhouseV1
  alias GreenhouseTycoon.ReadModels.Greenhouse

  @cache_name :greenhouse_read_models
  @test_greenhouse_id "test-greenhouse-set-temp-123"

  setup do
    Cachex.clear(@cache_name)
    create_test_greenhouse()
    :ok
  end

  test "handles TargetTemperatureSet event and updates read model" do
    set_at = DateTime.utc_now()
    event = %TargetTemperatureSetEvent{
      greenhouse_id: @test_greenhouse_id,
      target_temperature: 26.5,
      previous_target_temperature: 22.0,
      set_at: set_at
    }

    result = TargetTemperatureSetToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.target_temperature == 26.5
    assert read_model.updated_at == set_at
    assert read_model.event_count == 2
    assert read_model.current_temperature == nil
    assert read_model.name == "Test Greenhouse"
  end

  test "recalculates status after target temperature update" do
    # First set current temperature
    {:ok, initial_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    model_with_current = %{initial_model | current_temperature: 35.0}
    Cachex.put(@cache_name, @test_greenhouse_id, model_with_current)

    event = %TargetTemperatureSetEvent{
      greenhouse_id: @test_greenhouse_id,
      target_temperature: 34.0,  # 1 degree from current 35.0
      previous_target_temperature: 22.0,
      set_at: DateTime.utc_now()
    }

    TargetTemperatureSetToGreenhouseV1.handle(event, %{})

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.status == :active
    assert read_model.target_temperature == 34.0
  end

  test "returns error when greenhouse not found in cache" do
    event = %TargetTemperatureSetEvent{
      greenhouse_id: "non-existent-greenhouse",
      target_temperature: 20.0,
      previous_target_temperature: 18.0,
      set_at: DateTime.utc_now()
    }

    result = TargetTemperatureSetToGreenhouseV1.handle(event, %{})

    assert result == {:error, :greenhouse_not_found}
  end

  test "returns error when cache is not available" do
    cache_pid = Process.whereis(@cache_name)
    Process.exit(cache_pid, :kill)
    :timer.sleep(10)

    event = %TargetTemperatureSetEvent{
      greenhouse_id: @test_greenhouse_id,
      target_temperature: 20.0,
      previous_target_temperature: 18.0,
      set_at: DateTime.utc_now()
    }

    result = TargetTemperatureSetToGreenhouseV1.handle(event, %{})

    assert result == {:error, :cache_not_available}

    {:ok, _} = Cachex.start_link(@cache_name)
  end

  test "handles setting target temperature to zero" do
    event = %TargetTemperatureSetEvent{
      greenhouse_id: @test_greenhouse_id,
      target_temperature: 0.0,
      previous_target_temperature: 22.0,
      set_at: DateTime.utc_now()
    }

    result = TargetTemperatureSetToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.target_temperature == 0.0
  end

  test "handles negative target temperature" do
    event = %TargetTemperatureSetEvent{
      greenhouse_id: @test_greenhouse_id,
      target_temperature: -5.5,
      previous_target_temperature: 22.0,
      set_at: DateTime.utc_now()
    }

    result = TargetTemperatureSetToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.target_temperature == -5.5
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
