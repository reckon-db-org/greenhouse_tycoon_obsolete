defmodule ControlEquipment.Commands do
  @moduledoc """
  Commands for real-time equipment control operations.
  """

  # Basic operational control commands
  
  defmodule TurnOnEquipment do
    @moduledoc "Command to turn on equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id]
    defstruct [
      :equipment_id,
      :equipment_type,
      :greenhouse_id,
      :turned_on_by,
      :reason,
      :initial_parameters,
      :expected_runtime
    ]
  end

  defmodule TurnOffEquipment do
    @moduledoc "Command to turn off equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id]
    defstruct [
      :equipment_id,
      :equipment_type,
      :greenhouse_id,
      :turned_off_by,
      :reason,
      :graceful_shutdown
    ]
  end

  # Parameter adjustment commands

  defmodule AdjustEquipmentParameters do
    @moduledoc "Command to adjust equipment operating parameters."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :parameter_changes]
    defstruct [
      :equipment_id,
      :equipment_type,
      :greenhouse_id,
      :parameter_changes,
      :adjusted_by,
      :reason,
      :apply_gradually
    ]
  end

  # Specific equipment control commands

  defmodule ChangeFanSpeed do
    @moduledoc "Command to change fan speed."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :speed_percent]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :speed_percent,
      :ramp_time_seconds,
      :changed_by,
      :reason
    ]
  end

  defmodule SetHeaterTemperature do
    @moduledoc "Command to set heater temperature."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :target_temperature]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :target_temperature,
      :max_heating_rate,
      :set_by,
      :reason
    ]
  end

  defmodule ChangeLightingIntensity do
    @moduledoc "Command to change lighting intensity."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :intensity_percent]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :intensity_percent,
      :light_spectrum,
      :transition_time_minutes,
      :changed_by,
      :reason
    ]
  end

  defmodule ActivateIrrigationSystem do
    @moduledoc "Command to activate irrigation system."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :zone_id]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :zone_id,
      :flow_rate,
      :duration_minutes,
      :water_pressure,
      :activated_by,
      :reason
    ]
  end

  defmodule DeactivateIrrigationSystem do
    @moduledoc "Command to deactivate irrigation system."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :zone_id]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :zone_id,
      :deactivated_by,
      :reason,
      :emergency_stop
    ]
  end

  defmodule AdjustVentilationSystem do
    @moduledoc "Command to adjust ventilation system."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :vent_position_percent]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :vent_position_percent,
      :adjustment_speed,
      :adjusted_by,
      :reason
    ]
  end

  defmodule DeployShadingSystem do
    @moduledoc "Command to deploy shading system."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :shade_percent]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :shade_percent,
      :deployment_speed,
      :deployed_by,
      :reason
    ]
  end

  defmodule RetractShadingSystem do
    @moduledoc "Command to retract shading system."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :retraction_speed,
      :retracted_by,
      :reason
    ]
  end

  # Automated control commands

  defmodule EnableAutomatedControl do
    @moduledoc "Command to enable automated control for equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :control_mode]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :control_mode,
      :control_parameters,
      :sensor_inputs,
      :enabled_by
    ]
  end

  defmodule DisableAutomatedControl do
    @moduledoc "Command to disable automated control for equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :manual_override_reason,
      :disabled_by
    ]
  end

  defmodule UpdateAutomatedControlParameters do
    @moduledoc "Command to update automated control parameters."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :control_parameters]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :control_parameters,
      :sensor_inputs,
      :updated_by,
      :reason
    ]
  end

  # Safety and emergency commands

  defmodule EmergencyShutdown do
    @moduledoc "Command to perform emergency shutdown of equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :safety_condition]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :safety_condition,
      :triggered_by,
      :automatic_trigger,
      :override_code
    ]
  end

  defmodule ResetEquipmentAfterError do
    @moduledoc "Command to reset equipment after error condition."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :error_acknowledged,
      :corrective_action_taken,
      :reset_by,
      :reset_reason
    ]
  end

  # Status and monitoring commands

  defmodule RequestEquipmentStatus do
    @moduledoc "Command to request current equipment status."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :requested_by,
      :status_detail_level
    ]
  end

  defmodule CollectPerformanceMetrics do
    @moduledoc "Command to collect equipment performance metrics."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :metric_types,
      :collection_period,
      :requested_by
    ]
  end

  # Equipment group control commands

  defmodule ActivateEquipmentGroup do
    @moduledoc "Command to activate a group of equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:group_id, :equipment_ids]
    defstruct [
      :group_id,
      :equipment_ids,
      :greenhouse_id,
      :group_type,
      :activation_sequence,
      :stagger_delay_seconds,
      :activated_by,
      :reason
    ]
  end

  defmodule DeactivateEquipmentGroup do
    @moduledoc "Command to deactivate a group of equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:group_id, :equipment_ids]
    defstruct [
      :group_id,
      :equipment_ids,
      :greenhouse_id,
      :group_type,
      :deactivation_sequence,
      :stagger_delay_seconds,
      :deactivated_by,
      :reason
    ]
  end

  # Configuration commands

  defmodule ConfigureEquipmentLimits do
    @moduledoc "Command to configure operational limits for equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :operational_limits]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :operational_limits,
      :safety_margins,
      :configured_by,
      :reason
    ]
  end

  defmodule SetEquipmentSchedule do
    @moduledoc "Command to set operational schedule for equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :schedule]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :schedule,
      :schedule_type,
      :override_conditions,
      :set_by,
      :effective_from
    ]
  end
end
