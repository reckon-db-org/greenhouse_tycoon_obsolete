defmodule ControlEquipment.Events do
  @moduledoc """
  Events for real-time equipment control and operational state changes.
  """

  # Basic operational control events
  
  defmodule EquipmentTurnedOn do
    @moduledoc "Event raised when equipment is turned on."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :turned_on_at]
    defstruct [
      :equipment_id,
      :equipment_type,
      :greenhouse_id,
      :turned_on_by,
      :reason,
      :initial_parameters,
      :expected_power_consumption,
      :turned_on_at
    ]
  end

  defmodule EquipmentTurnedOff do
    @moduledoc "Event raised when equipment is turned off."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :turned_off_at]
    defstruct [
      :equipment_id,
      :equipment_type,
      :greenhouse_id,
      :turned_off_by,
      :reason,
      :final_parameters,
      :runtime_duration,
      :energy_consumed,
      :turned_off_at
    ]
  end

  # Parameter adjustment events

  defmodule EquipmentParametersAdjusted do
    @moduledoc "Event raised when equipment operating parameters are adjusted."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :parameter_changes, :adjusted_at]
    defstruct [
      :equipment_id,
      :equipment_type,
      :greenhouse_id,
      :parameter_changes,
      :previous_parameters,
      :adjusted_by,
      :reason,
      :adjusted_at
    ]
  end

  # Specific equipment control events

  defmodule FanSpeedChanged do
    @moduledoc "Event raised when fan speed is changed."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :new_speed_percent, :changed_at]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :new_speed_percent,
      :previous_speed_percent,
      :changed_by,
      :reason,
      :changed_at
    ]
  end

  defmodule HeaterTemperatureSet do
    @moduledoc "Event raised when heater temperature is set."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :target_temperature, :set_at]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :target_temperature,
      :previous_temperature,
      :set_by,
      :reason,
      :set_at
    ]
  end

  defmodule LightingIntensityChanged do
    @moduledoc "Event raised when lighting intensity is changed."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :intensity_percent, :changed_at]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :intensity_percent,
      :previous_intensity,
      :light_spectrum,
      :changed_by,
      :reason,
      :changed_at
    ]
  end

  defmodule IrrigationSystemActivated do
    @moduledoc "Event raised when irrigation system is activated."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :zone_id, :activated_at]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :zone_id,
      :flow_rate,
      :duration_minutes,
      :water_pressure,
      :activated_by,
      :reason,
      :activated_at
    ]
  end

  defmodule IrrigationSystemDeactivated do
    @moduledoc "Event raised when irrigation system is deactivated."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :zone_id, :deactivated_at]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :zone_id,
      :water_delivered,
      :actual_duration,
      :deactivated_by,
      :reason,
      :deactivated_at
    ]
  end

  defmodule VentilationSystemAdjusted do
    @moduledoc "Event raised when ventilation system is adjusted."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :vent_position_percent, :adjusted_at]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :vent_position_percent,
      :previous_position,
      :airflow_rate,
      :adjusted_by,
      :reason,
      :adjusted_at
    ]
  end

  defmodule ShadingSystemDeployed do
    @moduledoc "Event raised when shading system is deployed."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :shade_percent, :deployed_at]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :shade_percent,
      :previous_shade_percent,
      :deployment_speed,
      :deployed_by,
      :reason,
      :deployed_at
    ]
  end

  defmodule ShadingSystemRetracted do
    @moduledoc "Event raised when shading system is retracted."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :retracted_at]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :final_shade_percent,
      :retraction_speed,
      :retracted_by,
      :reason,
      :retracted_at
    ]
  end

  # Automated control events

  defmodule AutomatedControlEnabled do
    @moduledoc "Event raised when automated control is enabled for equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :control_mode, :enabled_at]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :control_mode,
      :control_parameters,
      :sensor_inputs,
      :enabled_by,
      :enabled_at
    ]
  end

  defmodule AutomatedControlDisabled do
    @moduledoc "Event raised when automated control is disabled for equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :disabled_at]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :previous_control_mode,
      :manual_override_reason,
      :disabled_by,
      :disabled_at
    ]
  end

  defmodule AutomatedControlTriggered do
    @moduledoc "Event raised when automated control takes action."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :trigger_condition, :action_taken, :triggered_at]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :trigger_condition,
      :sensor_readings,
      :action_taken,
      :control_algorithm,
      :triggered_at
    ]
  end

  # Error and safety events

  defmodule EquipmentControlError do
    @moduledoc "Event raised when equipment control encounters an error."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :error_type, :error_occurred_at]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :error_type,
      :error_message,
      :attempted_action,
      :system_state,
      :error_occurred_at
    ]
  end

  defmodule SafetyShutdownTriggered do
    @moduledoc "Event raised when safety shutdown is triggered."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :safety_condition, :triggered_at]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :safety_condition,
      :sensor_readings,
      :automatic_shutdown,
      :triggered_at
    ]
  end

  # Status and monitoring events

  defmodule EquipmentStatusReported do
    @moduledoc "Event raised when equipment status is reported."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :operational_status, :reported_at]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :operational_status,
      :current_parameters,
      :power_consumption,
      :runtime_hours,
      :last_command,
      :reported_at
    ]
  end

  defmodule EquipmentPerformanceMetrics do
    @moduledoc "Event raised when equipment performance metrics are collected."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :metrics, :collected_at]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :metrics,
      :efficiency_score,
      :energy_usage,
      :output_quality,
      :collected_at
    ]
  end

  # Equipment group control events

  defmodule EquipmentGroupActivated do
    @moduledoc "Event raised when a group of equipment is activated together."
    
    @derive Jason.Encoder
    @enforce_keys [:group_id, :equipment_ids, :activated_at]
    defstruct [
      :group_id,
      :equipment_ids,
      :greenhouse_id,
      :group_type,
      :activation_sequence,
      :activated_by,
      :reason,
      :activated_at
    ]
  end

  defmodule EquipmentGroupDeactivated do
    @moduledoc "Event raised when a group of equipment is deactivated together."
    
    @derive Jason.Encoder
    @enforce_keys [:group_id, :equipment_ids, :deactivated_at]
    defstruct [
      :group_id,
      :equipment_ids,
      :greenhouse_id,
      :group_type,
      :deactivation_sequence,
      :deactivated_by,
      :reason,
      :deactivated_at
    ]
  end
end
