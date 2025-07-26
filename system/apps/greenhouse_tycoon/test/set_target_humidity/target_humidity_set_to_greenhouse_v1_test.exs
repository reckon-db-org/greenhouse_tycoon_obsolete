defmodule GreenhouseTycoon.SetTargetHumidity.TargetHumiditySetToGreenhouseV1Test do
  use ExUnit.Case, async: false

  alias GreenhouseTycoon.SetTargetHumidity.EventV1, as: TargetHumiditySetEvent
  alias GreenhouseTycoon.SetTargetHumidity.TargetHumiditySetToGreenhouseV1
  alias GreenhouseTycoon.ReadModels.GreenhouseReadModel

  @cache_name :greenhouse_read_models
  @test_greenhouse_id "test-greenhouse-set-humidity-123"

  setup do
    Cachex.clear(@cache_name)
    create_test_greenhouse()
    :ok
  end

  test "handles TargetHumiditySet event and updates read model" do
    set_at = DateTime.utc_now()
    event = %TargetHumiditySetEvent{
      greenhouse_id: @test_greenhouse_id,
      target_humidity: 75.0,
      previous_target_humidity: 65.0,
      set_at: set_at
    }

    result = TargetHumiditySetToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.target_humidity == 75.0
    assert read_model.updated_at == set_at
    assert read_model.event_count == 2
    assert read_model.current_humidity == nil
    assert read_model.name == "Test Greenhouse"
  end

  test "recalculates status after target humidity update" do
    # First set current humidity
    {:ok, initial_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    model_with_current = %{initial_model | current_humidity: 50.0}
    Cachex.put(@cache_name, @test_greenhouse_id, model_with_current)

    event = %TargetHumiditySetEvent{
      greenhouse_id: @test_greenhouse_id,
      target_humidity: 52.0,  # 2% from current 50.0
      previous_target_humidity: 65.0,
      set_at: DateTime.utc_now()
    }

    TargetHumiditySetToGreenhouseV1.handle(event, %{})

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.status == :active
    assert read_model.target_humidity == 52.0
  end

  test "returns error when greenhouse not found in cache" do
    event = %TargetHumiditySetEvent{
      greenhouse_id: "non-existent-greenhouse",
      target_humidity: 70.0,
      previous_target_humidity: 65.0,
      set_at: DateTime.utc_now()
    }

    result = TargetHumiditySetToGreenhouseV1.handle(event, %{})

    assert result == {:error, :greenhouse_not_found}
  end

  test "returns error when cache is not available" do
    cache_pid = Process.whereis(@cache_name)
    Process.exit(cache_pid, :kill)
    :timer.sleep(10)

    event = %TargetHumiditySetEvent{
      greenhouse_id: @test_greenhouse_id,
      target_humidity: 70.0,
      previous_target_humidity: 65.0,
      set_at: DateTime.utc_now()
    }

    result = TargetHumiditySetToGreenhouseV1.handle(event, %{})

    assert result == {:error, :cache_not_available}

    {:ok, _} = Cachex.start_link(@cache_name)
  end

  test "handles setting target humidity to zero" do
    event = %TargetHumiditySetEvent{
      greenhouse_id: @test_greenhouse_id,
      target_humidity: 0.0,
      previous_target_humidity: 65.0,
      set_at: DateTime.utc_now()
    }

    result = TargetHumiditySetToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.target_humidity == 0.0
  end

  test "handles setting target humidity to maximum" do
    event = %TargetHumiditySetEvent{
      greenhouse_id: @test_greenhouse_id,
      target_humidity: 100.0,
      previous_target_humidity: 65.0,
      set_at: DateTime.utc_now()
    }

    result = TargetHumiditySetToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.target_humidity == 100.0
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
