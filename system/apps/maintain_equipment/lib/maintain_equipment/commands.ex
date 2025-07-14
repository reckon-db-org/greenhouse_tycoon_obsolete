defmodule MaintainEquipment.Commands do
  @moduledoc """
  Commands for equipment maintenance operations.
  """

  defmodule InstallEquipment do
    @moduledoc "Command to install new equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :greenhouse_id, :equipment_type]
    defstruct [
      :equipment_id,
      :greenhouse_id,
      :equipment_type,
      :manufacturer,
      :model,
      :serial_number,
      :installation_location,
      :installed_by,
      :warranty_period,
      :initial_condition
    ]
  end

  defmodule ActivateEquipment do
    @moduledoc "Command to activate equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id]
    defstruct [
      :equipment_id,
      :activated_by,
      :activation_reason,
      :operating_parameters
    ]
  end

  defmodule DeactivateEquipment do
    @moduledoc "Command to deactivate equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id]
    defstruct [
      :equipment_id,
      :deactivated_by,
      :deactivation_reason
    ]
  end

  defmodule UpdateEquipmentCondition do
    @moduledoc "Command to update equipment condition."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :condition_percentage]
    defstruct [
      :equipment_id,
      :condition_percentage,
      :wear_indicators,
      :assessed_by,
      :notes
    ]
  end

  defmodule ScheduleMaintenance do
    @moduledoc "Command to schedule equipment maintenance."
    
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
      :scheduled_by
    ]
  end

  defmodule StartMaintenance do
    @moduledoc "Command to start maintenance work."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :maintenance_id]
    defstruct [
      :equipment_id,
      :maintenance_id,
      :technician,
      :estimated_completion
    ]
  end

  defmodule CompleteMaintenance do
    @moduledoc "Command to complete maintenance work."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :maintenance_id]
    defstruct [
      :equipment_id,
      :maintenance_id,
      :technician,
      :parts_replaced,
      :work_performed,
      :post_maintenance_condition,
      :next_maintenance_due,
      :cost
    ]
  end

  defmodule ReportEquipmentFailure do
    @moduledoc "Command to report equipment failure."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :failure_type]
    defstruct [
      :equipment_id,
      :failure_type,
      :severity_level,
      :failure_symptoms,
      :probable_cause,
      :impact_on_operations,
      :detected_by,
      :requires_immediate_attention
    ]
  end

  defmodule RepairEquipment do
    @moduledoc "Command to repair failed equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :repair_id, :failure_type]
    defstruct [
      :equipment_id,
      :repair_id,
      :failure_type,
      :repair_actions,
      :parts_replaced,
      :technician,
      :cost,
      :warranty_extended
    ]
  end

  defmodule RequestEquipmentReplacement do
    @moduledoc "Command to request equipment replacement."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :replacement_reason]
    defstruct [
      :equipment_id,
      :replacement_reason,
      :current_condition,
      :end_of_life_indicators,
      :recommended_replacement,
      :required_by,
      :estimated_cost,
      :impact_if_delayed,
      :assessed_by
    ]
  end

  defmodule ReplaceEquipment do
    @moduledoc "Command to replace equipment."
    
    @derive Jason.Encoder
    @enforce_keys [:old_equipment_id, :new_equipment_id]
    defstruct [
      :old_equipment_id,
      :new_equipment_id,
      :replacement_reason,
      :old_equipment_disposal,
      :technician,
      :cost,
      :warranty_info
    ]
  end

  defmodule LogEquipmentPerformance do
    @moduledoc "Command to log equipment performance metrics."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :performance_metrics]
    defstruct [
      :equipment_id,
      :performance_metrics,
      :efficiency_rating,
      :energy_consumption,
      :output_metrics,
      :operating_hours,
      :anomalies_detected
    ]
  end

  defmodule RetireEquipment do
    @moduledoc "Command to retire equipment from service."
    
    @derive Jason.Encoder
    @enforce_keys [:equipment_id, :retirement_reason]
    defstruct [
      :equipment_id,
      :retirement_reason,
      :final_condition,
      :total_service_hours,
      :disposal_method,
      :retired_by,
      :replacement_equipment_id,
      :salvage_value
    ]
  end
end
