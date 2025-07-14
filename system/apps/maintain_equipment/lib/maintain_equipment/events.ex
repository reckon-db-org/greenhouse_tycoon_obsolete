defmodule MaintainEquipment.Events do
  @moduledoc """
  Events for equipment maintenance and monitoring.
  """

  defmodule EquipmentInstalled do
    @moduledoc "Event raised when equipment is installed in the greenhouse."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :greenhouse_id, :equipment_type, :installed_at]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :equipment_type,
      :manufacturer,
      :model,
      :serial_number,
      :installation_location,
      :installed_by,
      :installed_at,
      :warranty_expiry,
      :initial_condition
    ]
  end

  defmodule EquipmentActivated do
    @moduledoc "Event raised when equipment is activated/turned on."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :activated_at]
    defstruct [
      :equipment_id,
      :activated_by,
      :activation_reason,
      :power_consumption,
      :operating_parameters,
      :activated_at
    ]
  end

  defmodule EquipmentDeactivated do
    @moduledoc "Event raised when equipment is deactivated/turned off."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :deactivated_at]
    defstruct [
      :equipment_id,
      :deactivated_by,
      :deactivation_reason,
      :runtime_hours,
      :final_parameters,
      :deactivated_at
    ]
  end

  defmodule EquipmentConditionUpdated do
    @moduledoc "Event raised when equipment condition is assessed or updated."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :condition_percentage, :assessed_at]
    defstruct [
      :equipment_id,
      :condition_percentage,
      :previous_condition,
      :degradation_rate,
      :wear_indicators,
      :assessed_by,
      :assessed_at,
      :notes
    ]
  end

  defmodule EquipmentMaintenanceScheduled do
    @moduledoc "Event raised when maintenance is scheduled for equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :maintenance_type, :scheduled_for]
    defstruct [
      :equipment_id,
      :maintenance_type,
      :urgency_level,
      :estimated_duration,
      :required_parts,
      :assigned_technician,
      :scheduled_for,
      :scheduled_by,
      :scheduled_at
    ]
  end

  defmodule EquipmentMaintenanceStarted do
    @moduledoc "Event raised when maintenance begins on equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :maintenance_id, :started_at]
    defstruct [
      :equipment_id,
      :maintenance_id,
      :maintenance_type,
      :technician,
      :started_at,
      :estimated_completion
    ]
  end

  defmodule EquipmentMaintenanceCompleted do
    @moduledoc "Event raised when maintenance is completed on equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :maintenance_id, :completed_at]
    defstruct [
      :equipment_id,
      :maintenance_id,
      :maintenance_type,
      :technician,
      :completed_at,
      :actual_duration,
      :parts_replaced,
      :work_performed,
      :post_maintenance_condition,
      :next_maintenance_due,
      :cost
    ]
  end

  defmodule EquipmentFailureDetected do
    @moduledoc "Event raised when equipment failure is detected."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :failure_type, :detected_at]
    defstruct [
      :equipment_id,
      :failure_type,
      :severity_level,
      :failure_symptoms,
      :probable_cause,
      :impact_on_operations,
      :detected_by,
      :detected_at,
      :requires_immediate_attention
    ]
  end

  defmodule EquipmentRepaired do
    @moduledoc "Event raised when equipment is repaired after failure."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :repair_id, :repaired_at]
    defstruct [
      :equipment_id,
      :repair_id,
      :failure_type,
      :repair_actions,
      :parts_replaced,
      :technician,
      :repaired_at,
      :repair_duration,
      :cost,
      :warranty_extended,
      :post_repair_condition
    ]
  end

  defmodule EquipmentReplacementRequired do
    @moduledoc "Event raised when equipment requires replacement."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :replacement_reason, :required_by]
    defstruct [
      :equipment_id,
      :replacement_reason,
      :current_condition,
      :end_of_life_indicators,
      :recommended_replacement,
      :required_by,
      :estimated_cost,
      :impact_if_delayed,
      :assessed_by,
      :assessed_at
    ]
  end

  defmodule EquipmentReplaced do
    @moduledoc "Event raised when equipment is replaced."
    
    @derive Jason.Encoder
    @enforce_keys [:old_equipment_id, :new_equipment_id, :replaced_at]
    defstruct [
      :old_equipment_id,
      :new_equipment_id,
      :replacement_reason,
      :old_equipment_disposal,
      :technician,
      :replaced_at,
      :downtime_duration,
      :cost,
      :warranty_info
    ]
  end

  defmodule EquipmentPerformanceLogged do
    @moduledoc "Event raised when equipment performance metrics are logged."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :performance_metrics, :logged_at]
    defstruct [
      :equipment_id,
      :performance_metrics,
      :efficiency_rating,
      :energy_consumption,
      :output_metrics,
      :operating_hours,
      :logged_at,
      :anomalies_detected
    ]
  end

  defmodule EquipmentWarrantyExpired do
    @moduledoc "Event raised when equipment warranty expires."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :expired_at]
    defstruct [
      :equipment_id,
      :warranty_type,
      :original_warranty_period,
      :expired_at,
      :post_warranty_maintenance_plan,
      :extended_warranty_options
    ]
  end

  defmodule EquipmentRetired do
    @moduledoc "Event raised when equipment is retired from service."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :retired_at]
    defstruct [
      :equipment_id,
      :retirement_reason,
      :final_condition,
      :total_service_hours,
      :disposal_method,
      :retired_by,
      :retired_at,
      :replacement_equipment_id,
      :salvage_value
    ]
  end
end
