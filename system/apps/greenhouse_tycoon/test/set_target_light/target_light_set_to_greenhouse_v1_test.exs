defmodule GreenhouseTycoon.SetTargetLight.TargetLightSetToGreenhouseV1Test do
  use ExUnit.Case, async: false

  alias GreenhouseTycoon.SetTargetLight.EventV1, as: TargetLightSetEvent
  alias GreenhouseTycoon.SetTargetLight.TargetLightSetToGreenhouseV1
  alias GreenhouseTycoon.ReadModels.GreenhouseReadModel

  @cache_name :greenhouse_read_models
  @test_greenhouse_id "test-greenhouse-set-light-123"

  setup do
    Cachex.clear(@cache_name)
    create_test_greenhouse()
    :ok
  end

  test "handles TargetLightSet event and updates read model" do
    set_at = DateTime.utc_now()
    event = %TargetLightSetEvent{
      greenhouse_id: @test_greenhouse_id,
      target_light: 90.0,
      previous_target_light: nil,
      set_at: set_at
    }

    result = TargetLightSetToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.target_light == 90.0
    assert read_model.updated_at == set_at
    assert read_model.event_count == 2
    assert read_model.current_light == nil
    assert read_model.name == "Test Greenhouse"
  end

  test "recalculates status after target light update" do
    # First set current light
    {:ok, initial_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    model_with_current = %{initial_model | current_light: 120.0}
    Cachex.put(@cache_name, @test_greenhouse_id, model_with_current)

    event = %TargetLightSetEvent{
      greenhouse_id: @test_greenhouse_id,
      target_light: 115.0,  # 5 lumens from current 120.0
      previous_target_light: nil,
      set_at: DateTime.utc_now()
    }

    TargetLightSetToGreenhouseV1.handle(event, %{})

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.status == :active
    assert read_model.target_light == 115.0
  end

  test "returns error when greenhouse not found in cache" do
    event = %TargetLightSetEvent{
      greenhouse_id: "non-existent-greenhouse",
      target_light: 85.0,
      previous_target_light: nil,
      set_at: DateTime.utc_now()
    }

    result = TargetLightSetToGreenhouseV1.handle(event, %{})

    assert result == {:error, :greenhouse_not_found}
  end

  test "returns error when cache is not available" do
    cache_pid = Process.whereis(@cache_name)
    Process.exit(cache_pid, :kill)
    :timer.sleep(10)

    event = %TargetLightSetEvent{
      greenhouse_id: @test_greenhouse_id,
      target_light: 85.0,
      previous_target_light: nil,
      set_at: DateTime.utc_now()
    }

    result = TargetLightSetToGreenhouseV1.handle(event, %{})

    assert result == {:error, :cache_not_available}

    {:ok, _} = Cachex.start_link(@cache_name)
  end

  test "handles setting target light to zero" do
    event = %TargetLightSetEvent{
      greenhouse_id: @test_greenhouse_id,
      target_light: 0.0,
      previous_target_light: nil,
      set_at: DateTime.utc_now()
    }

    result = TargetLightSetToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.target_light == 0.0
  end

  test "handles setting high target light value" do
    event = %TargetLightSetEvent{
      greenhouse_id: @test_greenhouse_id,
      target_light: 200.0,
      previous_target_light: nil,
      set_at: DateTime.utc_now()
    }

    result = TargetLightSetToGreenhouseV1.handle(event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.target_light == 200.0
  end

  test "handles updating existing target light" do
    # First set a target light
    first_event = %TargetLightSetEvent{
      greenhouse_id: @test_greenhouse_id,
      target_light: 75.0,
      previous_target_light: nil,
      set_at: DateTime.utc_now()
    }

    TargetLightSetToGreenhouseV1.handle(first_event, %{})

    # Now update it
    set_at = DateTime.utc_now()
    second_event = %TargetLightSetEvent{
      greenhouse_id: @test_greenhouse_id,
      target_light: 95.0,
      previous_target_light: 75.0,
      set_at: set_at
    }

    result = TargetLightSetToGreenhouseV1.handle(second_event, %{})

    assert result == :ok

    {:ok, read_model} = Cachex.get(@cache_name, @test_greenhouse_id)
    assert read_model.target_light == 95.0
    assert read_model.updated_at == set_at
    assert read_model.event_count == 3  # initial + 2 updates
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
