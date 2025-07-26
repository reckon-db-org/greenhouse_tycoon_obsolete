defmodule GreenhouseTycoon.AggregateIntegrationTest do
  use ExUnit.Case, async: true

  alias GreenhouseTycoon.Greenhouse

  # Command modules
  alias GreenhouseTycoon.InitializeGreenhouse.CommandV1, as: InitializeCommand
  alias GreenhouseTycoon.SetTargetTemperature.CommandV1, as: SetTargetTempCommand
  alias GreenhouseTycoon.MeasureTemperature.CommandV1, as: MeasureTempCommand

  @greenhouse_id "test-integration-greenhouse"
  @test_name "Test Integration Greenhouse"
  @test_location "Test Location"
  @test_city "Sydney"
  @test_country "Australia"

  describe "Aggregate delegation and error handling" do
    test "delegates InitializeGreenhouse command to vertical slice handler" do
      greenhouse = %Greenhouse{}
      command = InitializeCommand.new(%{
        greenhouse_id: @greenhouse_id,
        name: @test_name,
        location: @test_location,
        city: @test_city,
        country: @test_country
      })

      # Should delegate to InitializeGreenhouse.MaybeInitializeGreenhouseV1.execute/2
      {:ok, [event]} = Greenhouse.execute(greenhouse, command)

      # Verify we get the expected event type from the slice
      assert event.__struct__ == GreenhouseTycoon.InitializeGreenhouse.EventV1
      assert event.greenhouse_id == @greenhouse_id
    end

    test "delegates SetTargetTemperature command to vertical slice handler" do
      greenhouse = %Greenhouse{greenhouse_id: @greenhouse_id}
      {:ok, command} = SetTargetTempCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_temperature: 24.5,
        set_by: "test_user"
      })

      # Should delegate to SetTargetTemperature.MaybeSetTargetTemperatureV1.execute/2
      {:ok, [event]} = Greenhouse.execute(greenhouse, command)

      # Verify we get the expected event type from the slice
      assert event.__struct__ == GreenhouseTycoon.SetTargetTemperature.EventV1
      assert event.target_temperature == 24.5
    end

    test "returns error when greenhouse is not initialized (nil greenhouse_id)" do
      greenhouse = %Greenhouse{greenhouse_id: nil}
      {:ok, command} = SetTargetTempCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_temperature: 24.5,
        set_by: "test_user"
      })

      # This should be handled by the slice handler, not the aggregate
      result = Greenhouse.execute(greenhouse, command)
      
      assert {:error, :greenhouse_not_found} = result
    end

    test "delegates event application to vertical slice handlers" do
      greenhouse = %Greenhouse{}
      
      # Create an initialization event
      init_event = %GreenhouseTycoon.InitializeGreenhouse.EventV1{
        greenhouse_id: @greenhouse_id,
        name: @test_name,
        location: @test_location,
        city: @test_city,
        country: @test_country,
        target_temperature: 22.0,
        initialized_at: DateTime.utc_now(),
        version: 1
      }

      # Should delegate to InitializeGreenhouse.InitializedToAggregateV1.apply/2
      updated_greenhouse = Greenhouse.apply(greenhouse, init_event)

      assert updated_greenhouse.greenhouse_id == @greenhouse_id
      assert updated_greenhouse.name == @test_name
      assert updated_greenhouse.target_temperature == 22.0
    end
  end

  describe "Cross-slice integration workflows" do
    test "initialization enables other slice operations" do
      # Start with empty aggregate
      greenhouse = %Greenhouse{}

      # 1. Initialize greenhouse (enables other operations)
      init_command = InitializeCommand.new(%{
        greenhouse_id: @greenhouse_id,
        name: @test_name,
        location: @test_location,
        city: @test_city,
        country: @test_country,
        target_temperature: 22.0
      })

      {:ok, [init_event]} = Greenhouse.execute(greenhouse, init_command)
      greenhouse = Greenhouse.apply(greenhouse, init_event)

      # 2. Now we can execute commands that require initialized state
      {:ok, temp_command} = SetTargetTempCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_temperature: 25.0,
        set_by: "operator"
      })

      {:ok, [temp_event]} = Greenhouse.execute(greenhouse, temp_command)
      greenhouse = Greenhouse.apply(greenhouse, temp_event)

      # 3. Record measurements against the initialized greenhouse
      {:ok, measure_command} = MeasureTempCommand.new(%{
        greenhouse_id: @greenhouse_id,
        temperature: 24.8
      })

      {:ok, [measure_event]} = Greenhouse.execute(greenhouse, measure_command)
      greenhouse = Greenhouse.apply(greenhouse, measure_event)

      # Verify the cross-slice state coordination
      assert greenhouse.greenhouse_id == @greenhouse_id        # From initialization
      assert greenhouse.target_temperature == 25.0            # From set target
      assert greenhouse.current_temperature == 24.8           # From measurement
      assert greenhouse.name == @test_name                     # Preserved from init
    end

    test "maintains aggregate consistency across slice operations" do
      # Initialize
      greenhouse = %Greenhouse{}
      init_command = InitializeCommand.new(%{
        greenhouse_id: @greenhouse_id,
        name: @test_name,
        location: @test_location,
        city: @test_city,
        country: @test_country
      })

      {:ok, [init_event]} = Greenhouse.execute(greenhouse, init_command)
      greenhouse = Greenhouse.apply(greenhouse, init_event)

      # Multiple operations should all maintain aggregate integrity
      {:ok, temp_command} = SetTargetTempCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_temperature: 23.0,
        set_by: "operator"
      })

      {:ok, [temp_event]} = Greenhouse.execute(greenhouse, temp_command)
      greenhouse = Greenhouse.apply(greenhouse, temp_event)

      {:ok, measure_command} = MeasureTempCommand.new(%{
        greenhouse_id: @greenhouse_id,
        temperature: 22.8
      })

      {:ok, [measure_event]} = Greenhouse.execute(greenhouse, measure_command)
      greenhouse = Greenhouse.apply(greenhouse, measure_event)

      # All greenhouse metadata should be preserved across operations
      assert greenhouse.greenhouse_id == @greenhouse_id
      assert greenhouse.name == @test_name
      assert greenhouse.location == @test_location
      assert greenhouse.city == @test_city
      assert greenhouse.country == @test_country
      
      # Operational state should be current
      assert greenhouse.target_temperature == 23.0
      assert greenhouse.current_temperature == 22.8
      
      # Timestamps should be updated
      assert greenhouse.updated_at != greenhouse.created_at
    end

    test "target and current values are independent across slices" do
      # Initialize with targets
      greenhouse = %Greenhouse{}
      init_command = InitializeCommand.new(%{
        greenhouse_id: @greenhouse_id,
        name: @test_name,
        location: @test_location,
        city: @test_city,
        country: @test_country,
        target_temperature: 24.0,
        target_humidity: 70.0,
        target_light: 1500.0
      })

      {:ok, [init_event]} = Greenhouse.execute(greenhouse, init_command)
      greenhouse = Greenhouse.apply(greenhouse, init_event)

      # Changing one target shouldn't affect others
      {:ok, temp_command} = SetTargetTempCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_temperature: 26.0,
        set_by: "operator"
      })

      {:ok, [temp_event]} = Greenhouse.execute(greenhouse, temp_command)
      greenhouse = Greenhouse.apply(greenhouse, temp_event)

      # Recording measurements shouldn't affect targets
      {:ok, measure_command} = MeasureTempCommand.new(%{
        greenhouse_id: @greenhouse_id,
        temperature: 25.2
      })

      {:ok, [measure_event]} = Greenhouse.execute(greenhouse, measure_command)
      greenhouse = Greenhouse.apply(greenhouse, measure_event)

      # Verify independence
      assert greenhouse.target_temperature == 26.0    # Updated by command
      assert greenhouse.current_temperature == 25.2   # Updated by measurement
      assert greenhouse.target_humidity == 70.0       # Unchanged
      assert greenhouse.target_light == 1500.0        # Unchanged
      assert greenhouse.current_humidity == nil       # No measurements recorded
      assert greenhouse.current_light == nil          # No measurements recorded
    end
  end

  describe "Aggregate state transitions" do
    test "tracks creation and update timestamps correctly" do
      greenhouse = %Greenhouse{}
      creation_time = DateTime.utc_now()
      
      init_command = InitializeCommand.new(%{
        greenhouse_id: @greenhouse_id,
        name: @test_name,
        location: @test_location,
        city: @test_city,
        country: @test_country,
        requested_at: creation_time
      })

      {:ok, [init_event]} = Greenhouse.execute(greenhouse, init_command)
      greenhouse = Greenhouse.apply(greenhouse, init_event)

      assert greenhouse.created_at == creation_time
      assert greenhouse.updated_at == creation_time

      # Later operation should update timestamp
      Process.sleep(10)  # Ensure time difference
      
      {:ok, temp_command} = SetTargetTempCommand.new(%{
        greenhouse_id: @greenhouse_id,
        target_temperature: 25.0,
        set_by: "operator"
      })

      {:ok, [temp_event]} = Greenhouse.execute(greenhouse, temp_command)
      greenhouse = Greenhouse.apply(greenhouse, temp_event)

      assert greenhouse.created_at == creation_time  # Should not change
      assert greenhouse.updated_at != creation_time   # Should be updated
      assert DateTime.compare(greenhouse.updated_at, creation_time) == :gt
    end
  end
end
