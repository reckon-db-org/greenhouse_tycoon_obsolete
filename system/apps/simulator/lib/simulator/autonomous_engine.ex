defmodule Simulator.AutonomousEngine do
  @moduledoc """
  Autonomous simulation engine that operates independently to create realistic
  greenhouse scenarios by analyzing environmental conditions and triggering
  appropriate commands and events.
  
  This engine implements intelligent rules for:
  - Equipment control based on environmental conditions
  - Crop growth simulation
  - Supply consumption
  - Equipment degradation
  - Automated responses to environmental changes
  """

  use GenServer
  require Logger

  # Simulation intervals
  @simulation_tick_interval :timer.seconds(30)
  @crop_growth_interval :timer.minutes(5)
  @equipment_check_interval :timer.minutes(10)
  @supply_check_interval :timer.minutes(15)

  # Environmental thresholds
  @ideal_temperature_range 18..25
  @ideal_humidity_range 60..80
  @ideal_light_level 500..800

  # Equipment control parameters
  @fan_speed_adjustment_rate 10
  @heater_response_time 30
  @irrigation_duration_minutes 15

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    Logger.info("AutonomousEngine: Starting simulation engine")
    
    # Schedule various simulation activities
    schedule_simulation_tick()
    schedule_crop_growth_simulation()
    schedule_equipment_checks()
    schedule_supply_checks()
    
    initial_state = %{
      active_greenhouses: [],
      environmental_data: %{},
      equipment_states: %{},
      crop_states: %{},
      supply_levels: %{},
      last_actions: %{}
    }
    
    {:ok, initial_state}
  end

  # Main simulation tick - runs every 30 seconds
  def handle_info(:simulation_tick, state) do
    Logger.debug("AutonomousEngine: Running simulation tick")
    
    new_state = state
    |> update_environmental_conditions()
    |> analyze_and_respond_to_conditions()
    |> update_equipment_operational_status()
    
    schedule_simulation_tick()
    {:noreply, new_state}
  end

  # Crop growth simulation - runs every 5 minutes
  def handle_info(:crop_growth_simulation, state) do
    Logger.debug("AutonomousEngine: Running crop growth simulation")
    
    new_state = simulate_crop_growth(state)
    schedule_crop_growth_simulation()
    {:noreply, new_state}
  end

  # Equipment checks - runs every 10 minutes
  def handle_info(:equipment_checks, state) do
    Logger.debug("AutonomousEngine: Running equipment checks")
    
    new_state = simulate_equipment_degradation(state)
    schedule_equipment_checks()
    {:noreply, new_state}
  end

  # Supply checks - runs every 15 minutes
  def handle_info(:supply_checks, state) do
    Logger.debug("AutonomousEngine: Running supply checks")
    
    new_state = simulate_supply_consumption(state)
    schedule_supply_checks()
    {:noreply, new_state}
  end

  # Private functions for scheduling
  defp schedule_simulation_tick do
    Process.send_after(self(), :simulation_tick, @simulation_tick_interval)
  end

  defp schedule_crop_growth_simulation do
    Process.send_after(self(), :crop_growth_simulation, @crop_growth_interval)
  end

  defp schedule_equipment_checks do
    Process.send_after(self(), :equipment_checks, @equipment_check_interval)
  end

  defp schedule_supply_checks do
    Process.send_after(self(), :supply_checks, @supply_check_interval)
  end

  # Environmental condition analysis and response
  defp update_environmental_conditions(state) do
    # This would fetch current greenhouse conditions from RegulateGreenhouse
    # For now, we'll simulate some conditions
    mock_environmental_data = %{
      temperature: 22.5 + :rand.uniform() * 5 - 2.5,  # 20-25°C range
      humidity: 70 + :rand.uniform() * 20 - 10,        # 60-80% range  
      light: 600 + :rand.uniform() * 200 - 100        # 500-700 lux range
    }
    
    Logger.debug("AutonomousEngine: Environmental conditions: #{inspect(mock_environmental_data)}")
    
    %{state | environmental_data: mock_environmental_data}
  end

  defp analyze_and_respond_to_conditions(state) do
    env = state.environmental_data
    
    # Temperature control logic
    state = if env.temperature < @ideal_temperature_range.first do
      trigger_heating(state, env.temperature)
    else
      state
    end
    
    state = if env.temperature > @ideal_temperature_range.last do
      trigger_cooling(state, env.temperature)
    else
      state
    end
    
    # Humidity control logic
    state = if env.humidity < @ideal_humidity_range.first do
      trigger_humidification(state, env.humidity)
    else
      state
    end
    
    state = if env.humidity > @ideal_humidity_range.last do
      trigger_dehumidification(state, env.humidity)
    else
      state
    end
    
    # Light control logic
    state = if env.light < @ideal_light_level.first do
      trigger_supplemental_lighting(state, env.light)
    else
      state
    end
    
    state
  end

  defp trigger_heating(state, current_temp) do
    target_temp = @ideal_temperature_range.first + 2
    Logger.info("AutonomousEngine: Temperature too low (#{current_temp}°C), activating heaters to #{target_temp}°C")
    
    # This would trigger actual commands to ControlEquipment
    simulate_equipment_command(:heater, :activate, %{target_temperature: target_temp})
    
    record_action(state, :heating, %{current_temp: current_temp, target_temp: target_temp})
  end

  defp trigger_cooling(state, current_temp) do
    fan_speed = min(100, 50 + (current_temp - @ideal_temperature_range.last) * 10)
    Logger.info("AutonomousEngine: Temperature too high (#{current_temp}°C), activating fans at #{fan_speed}%")
    
    # This would trigger actual commands to ControlEquipment
    simulate_equipment_command(:fan, :activate, %{speed_percent: fan_speed})
    
    record_action(state, :cooling, %{current_temp: current_temp, fan_speed: fan_speed})
  end

  defp trigger_humidification(state, current_humidity) do
    Logger.info("AutonomousEngine: Humidity too low (#{current_humidity}%), activating irrigation system")
    
    # This would trigger actual commands to ControlEquipment
    simulate_equipment_command(:irrigation, :activate, %{duration_minutes: @irrigation_duration_minutes})
    
    record_action(state, :humidification, %{current_humidity: current_humidity})
  end

  defp trigger_dehumidification(state, current_humidity) do
    Logger.info("AutonomousEngine: Humidity too high (#{current_humidity}%), activating ventilation")
    
    # This would trigger actual commands to ControlEquipment
    simulate_equipment_command(:ventilation, :activate, %{vent_position_percent: 75})
    
    record_action(state, :dehumidification, %{current_humidity: current_humidity})
  end

  defp trigger_supplemental_lighting(state, current_light) do
    intensity = min(100, 60 + ((@ideal_light_level.first - current_light) / 10))
    Logger.info("AutonomousEngine: Light level too low (#{current_light} lux), activating grow lights at #{intensity}%")
    
    # This would trigger actual commands to ControlEquipment
    simulate_equipment_command(:lighting, :activate, %{intensity_percent: intensity})
    
    record_action(state, :supplemental_lighting, %{current_light: current_light, intensity: intensity})
  end

  defp update_equipment_operational_status(state) do
    # Monitor equipment runtime and trigger status updates
    # This would integrate with actual equipment monitoring
    Logger.debug("AutonomousEngine: Updating equipment operational status")
    state
  end

  defp simulate_crop_growth(state) do
    Logger.debug("AutonomousEngine: Simulating crop growth")
    
    # Simulate crop growth based on environmental conditions
    env = state.environmental_data
    
    # Growth rate influenced by environmental factors
    growth_rate = calculate_growth_rate(env)
    
    # Simulate various crop growth events
    if :rand.uniform() < 0.3 do  # 30% chance per growth cycle
      simulate_crop_event(growth_rate)
    end
    
    state
  end

  defp calculate_growth_rate(env) do
    temp_factor = if env.temperature in @ideal_temperature_range, do: 1.0, else: 0.7
    humidity_factor = if env.humidity in @ideal_humidity_range, do: 1.0, else: 0.8
    light_factor = if env.light in @ideal_light_level, do: 1.0, else: 0.6
    
    base_rate = 0.1
    base_rate * temp_factor * humidity_factor * light_factor
  end

  defp simulate_crop_event(growth_rate) do
    crop_id = "crop_#{:rand.uniform(1000)}"
    
    cond do
      growth_rate > 0.8 ->
        Logger.info("AutonomousEngine: Crop #{crop_id} showing excellent growth")
        simulate_crop_command(:update_growth, %{crop_id: crop_id, growth_stage: "vigorous", health_status: "excellent"})
      
      growth_rate > 0.6 ->
        Logger.info("AutonomousEngine: Crop #{crop_id} showing good growth")
        simulate_crop_command(:update_growth, %{crop_id: crop_id, growth_stage: "healthy", health_status: "good"})
      
      growth_rate > 0.4 ->
        Logger.info("AutonomousEngine: Crop #{crop_id} showing slow growth")
        simulate_crop_command(:update_growth, %{crop_id: crop_id, growth_stage: "slow", health_status: "fair"})
      
      true ->
        Logger.warn("AutonomousEngine: Crop #{crop_id} showing stress signs")
        simulate_crop_command(:update_growth, %{crop_id: crop_id, growth_stage: "stressed", health_status: "poor"})
    end
  end

  defp simulate_equipment_degradation(state) do
    Logger.debug("AutonomousEngine: Simulating equipment degradation")
    
    # Simulate equipment wear and potential failures
    equipment_types = [:fan, :heater, :irrigation, :lighting, :ventilation]
    
    Enum.each(equipment_types, fn equipment_type ->
      # Random chance of degradation
      if :rand.uniform() < 0.1 do  # 10% chance per check
        simulate_equipment_degradation_event(equipment_type)
      end
    end)
    
    state
  end

  defp simulate_equipment_degradation_event(equipment_type) do
    equipment_id = "#{equipment_type}_#{:rand.uniform(100)}"
    condition_change = :rand.uniform() * 5  # 0-5% degradation
    new_condition = max(0, 100 - condition_change)
    
    Logger.info("AutonomousEngine: #{equipment_type} #{equipment_id} degraded to #{new_condition}%")
    
    # This would trigger actual commands to MaintainEquipment
    simulate_maintenance_command(:update_condition, %{
      equipment_id: equipment_id,
      condition_percentage: new_condition,
      degradation_type: :normal_wear
    })
    
    # Trigger maintenance if condition is low
    if new_condition < 30 do
      Logger.warn("AutonomousEngine: #{equipment_type} #{equipment_id} requires maintenance")
      simulate_maintenance_command(:schedule_maintenance, %{
        equipment_id: equipment_id,
        maintenance_type: :preventive,
        urgency_level: :high
      })
    end
  end

  defp simulate_supply_consumption(state) do
    Logger.debug("AutonomousEngine: Simulating supply consumption")
    
    # Simulate consumption of various supplies
    supplies = [:fertilizer, :water, :potting_soil, :nutrients, :seeds, :pesticides]
    
    Enum.each(supplies, fn supply_type ->
      # Random consumption amount
      consumption = :rand.uniform() * 10  # 0-10 units
      
      Logger.info("AutonomousEngine: Consuming #{consumption} units of #{supply_type}")
      
      # This would trigger actual commands to ProcureSupplies
      simulate_supply_command(:consume, %{
        supply_type: supply_type,
        quantity: consumption,
        consumed_for: :crop_maintenance
      })
      
      # Check if reorder is needed (simulate low stock)
      if :rand.uniform() < 0.05 do  # 5% chance per check
        Logger.warn("AutonomousEngine: #{supply_type} stock low, triggering reorder")
        simulate_supply_command(:trigger_reorder, %{
          supply_type: supply_type,
          reorder_quantity: 100,
          urgency: :medium
        })
      end
    end)
    
    state
  end

  # Helper functions for command simulation
  defp simulate_equipment_command(equipment_type, action, params) do
    Logger.debug("AutonomousEngine: Simulating equipment command: #{equipment_type} #{action} #{inspect(params)}")
    # This would actually dispatch commands to ControlEquipment
    # For now, just log the action
  end

  defp simulate_crop_command(action, params) do
    Logger.debug("AutonomousEngine: Simulating crop command: #{action} #{inspect(params)}")
    # This would actually dispatch commands to ManageCrops
    # For now, just log the action
  end

  defp simulate_maintenance_command(action, params) do
    Logger.debug("AutonomousEngine: Simulating maintenance command: #{action} #{inspect(params)}")
    # This would actually dispatch commands to MaintainEquipment
    # For now, just log the action
  end

  defp simulate_supply_command(action, params) do
    Logger.debug("AutonomousEngine: Simulating supply command: #{action} #{inspect(params)}")
    # This would actually dispatch commands to ProcureSupplies
    # For now, just log the action
  end

  defp record_action(state, action_type, params) do
    action_record = %{
      action_type: action_type,
      params: params,
      timestamp: DateTime.utc_now()
    }
    
    last_actions = Map.put(state.last_actions, action_type, action_record)
    %{state | last_actions: last_actions}
  end

  # Public API for external interaction
  def get_simulation_status do
    GenServer.call(__MODULE__, :get_status)
  end

  def handle_call(:get_status, _from, state) do
    status = %{
      active_greenhouses: length(state.active_greenhouses),
      environmental_data: state.environmental_data,
      last_actions: state.last_actions,
      simulation_health: :healthy
    }
    {:reply, status, state}
  end
end
