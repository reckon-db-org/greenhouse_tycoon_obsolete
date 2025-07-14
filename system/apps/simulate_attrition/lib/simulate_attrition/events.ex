defmodule SimulateAttrition.Events do
  @moduledoc """
  Events emitted by the supply attrition simulation system.
  """

  defmodule SupplyAttritionSimulationStarted do
    @moduledoc "Event raised when supply attrition simulation starts for a greenhouse."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :started_at]
    defstruct [
      :greenhouse_id,
      :simulation_config,
      :initial_supply_levels,
      :started_at
    ]
  end

  defmodule SupplyAttritionSimulationStopped do
    @moduledoc "Event raised when supply attrition simulation stops for a greenhouse."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :stopped_at]
    defstruct [
      :greenhouse_id,
      :final_supply_levels,
      :simulation_duration,
      :stopped_at
    ]
  end

  defmodule SupplyNaturallyDepleted do
    @moduledoc "Event raised when supply is naturally depleted through usage/time."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :supply_type, :quantity_depleted, :depleted_at]
    defstruct [
      :greenhouse_id,
      :supply_type,
      :quantity_depleted,
      :depletion_reason,
      :remaining_quantity,
      :depletion_rate,
      :environmental_factors,
      :depleted_at
    ]
  end

  defmodule SupplyExpired do
    @moduledoc "Event raised when supply expires and becomes unusable."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :supply_type, :expired_quantity, :expired_at]
    defstruct [
      :greenhouse_id,
      :supply_type,
      :expired_quantity,
      :batch_number,
      :original_expiration_date,
      :storage_conditions,
      :expired_at
    ]
  end

  defmodule SupplyDegraded do
    @moduledoc "Event raised when supply quality degrades due to environmental factors."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :supply_type, :degradation_percentage, :degraded_at]
    defstruct [
      :greenhouse_id,
      :supply_type,
      :degradation_percentage,
      :quality_before,
      :quality_after,
      :degradation_factors,
      :impact_on_usability,
      :degraded_at
    ]
  end

  defmodule SupplyConsumedByEquipment do
    @moduledoc "Event raised when equipment consumes supplies during operation."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :supply_type, :quantity_consumed, :consumed_at]
    defstruct [
      :greenhouse_id,
      :supply_type,
      :quantity_consumed,
      :equipment_id,
      :equipment_type,
      :operation_duration,
      :consumption_rate,
      :remaining_quantity,
      :consumed_at
    ]
  end

  defmodule SupplyWasted do
    @moduledoc "Event raised when supply is wasted due to spillage, handling, etc."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :supply_type, :quantity_wasted, :wasted_at]
    defstruct [
      :greenhouse_id,
      :supply_type,
      :quantity_wasted,
      :waste_reason,
      :waste_type,
      :preventable,
      :cost_impact,
      :wasted_at
    ]
  end

  defmodule SupplyLevelCritical do
    @moduledoc "Event raised when supply levels reach critical thresholds."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :supply_type, :current_level, :critical_at]
    defstruct [
      :greenhouse_id,
      :supply_type,
      :current_level,
      :critical_threshold,
      :estimated_depletion_date,
      :recommended_reorder_quantity,
      :urgency_level,
      :critical_at
    ]
  end

  defmodule SupplyUsagePatternDetected do
    @moduledoc "Event raised when unusual usage patterns are detected."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :supply_type, :pattern_type, :detected_at]
    defstruct [
      :greenhouse_id,
      :supply_type,
      :pattern_type,
      :consumption_rate_change,
      :expected_vs_actual,
      :potential_causes,
      :recommendation,
      :detected_at
    ]
  end

  defmodule SupplyStorageConditionChanged do
    @moduledoc "Event raised when storage conditions affect supply quality."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :storage_location, :condition_change, :changed_at]
    defstruct [
      :greenhouse_id,
      :storage_location,
      :condition_change,
      :affected_supplies,
      :temperature_change,
      :humidity_change,
      :expected_impact,
      :changed_at
    ]
  end
end
