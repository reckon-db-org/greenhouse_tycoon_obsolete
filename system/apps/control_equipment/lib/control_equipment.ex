defmodule ControlEquipment do
  @moduledoc """
  Equipment Control System for Greenhouse Operations.
  
  This module provides the main API for controlling greenhouse equipment in real-time.
  It focuses on operational control rather than maintenance, including:
  
  - Turning equipment on/off
  - Adjusting operational parameters
  - Automated control management
  - Safety and emergency procedures
  - Performance monitoring
  
  The system is designed to be responsive and handle real-time control requirements
  while maintaining safety and operational integrity.
  """

  alias ControlEquipment.{Commands, Events}
  require Logger

  @doc """
  Turns on a piece of equipment.
  """
  def turn_on_equipment(equipment_id, opts \\ []) do
    command = %Commands.TurnOnEquipment{
      equipment_id: equipment_id,
      equipment_type: Keyword.get(opts, :equipment_type),
      greenhouse_id: Keyword.get(opts, :greenhouse_id),
      turned_on_by: Keyword.get(opts, :turned_on_by),
      reason: Keyword.get(opts, :reason),
      initial_parameters: Keyword.get(opts, :initial_parameters),
      expected_runtime: Keyword.get(opts, :expected_runtime)
    }
    
    Logger.info("Turning on equipment: #{equipment_id}")
    # Command would be dispatched to equipment controller
    {:ok, command}
  end

  @doc """
  Turns off a piece of equipment.
  """
  def turn_off_equipment(equipment_id, opts \\ []) do
    command = %Commands.TurnOffEquipment{
      equipment_id: equipment_id,
      equipment_type: Keyword.get(opts, :equipment_type),
      greenhouse_id: Keyword.get(opts, :greenhouse_id),
      turned_off_by: Keyword.get(opts, :turned_off_by),
      reason: Keyword.get(opts, :reason),
      graceful_shutdown: Keyword.get(opts, :graceful_shutdown, true)
    }
    
    Logger.info("Turning off equipment: #{equipment_id}")
    # Command would be dispatched to equipment controller
    {:ok, command}
  end

  @doc """
  Adjusts equipment parameters.
  """
  def adjust_equipment_parameters(equipment_id, parameter_changes, opts \\ []) do
    command = %Commands.AdjustEquipmentParameters{
      equipment_id: equipment_id,
      parameter_changes: parameter_changes,
      equipment_type: Keyword.get(opts, :equipment_type),
      greenhouse_id: Keyword.get(opts, :greenhouse_id),
      adjusted_by: Keyword.get(opts, :adjusted_by),
      reason: Keyword.get(opts, :reason),
      apply_gradually: Keyword.get(opts, :apply_gradually, true)
    }
    
    Logger.info("Adjusting equipment parameters: #{equipment_id}")
    # Command would be dispatched to equipment controller
    {:ok, command}
  end

  @doc """
  Changes fan speed.
  """
  def change_fan_speed(equipment_id, speed_percent, opts \\ []) do
    command = %Commands.ChangeFanSpeed{
      equipment_id: equipment_id,
      speed_percent: speed_percent,
      greenhouse_id: Keyword.get(opts, :greenhouse_id),
      ramp_time_seconds: Keyword.get(opts, :ramp_time_seconds, 10),
      changed_by: Keyword.get(opts, :changed_by),
      reason: Keyword.get(opts, :reason)
    }
    
    Logger.info("Changing fan speed: #{equipment_id} to #{speed_percent}%")
    # Command would be dispatched to equipment controller
    {:ok, command}
  end

  @doc """
  Performs emergency shutdown of equipment.
  """
  def emergency_shutdown(equipment_id, safety_condition, opts \\ []) do
    command = %Commands.EmergencyShutdown{
      equipment_id: equipment_id,
      safety_condition: safety_condition,
      greenhouse_id: Keyword.get(opts, :greenhouse_id),
      triggered_by: Keyword.get(opts, :triggered_by),
      automatic_trigger: Keyword.get(opts, :automatic_trigger, false),
      override_code: Keyword.get(opts, :override_code)
    }
    
    Logger.error("Emergency shutdown triggered for equipment: #{equipment_id}, condition: #{safety_condition}")
    # Command would be dispatched immediately to equipment controller
    {:ok, command}
  end

  @doc """
  Gets current equipment status.
  """
  def get_equipment_status(equipment_id, opts \\ []) do
    command = %Commands.RequestEquipmentStatus{
      equipment_id: equipment_id,
      greenhouse_id: Keyword.get(opts, :greenhouse_id),
      requested_by: Keyword.get(opts, :requested_by),
      status_detail_level: Keyword.get(opts, :status_detail_level, :basic)
    }
    
    Logger.info("Requesting status for equipment: #{equipment_id}")
    # Command would be dispatched to equipment controller
    {:ok, command}
  end
end
