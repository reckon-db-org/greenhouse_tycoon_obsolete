defmodule ProcureSupplies.Events do
  @moduledoc """
  Events for managing supply inventory and procurement processes.
  """

  defmodule SupplyAdded do
    @moduledoc "Event raised when supply is added to the inventory."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :quantity, :added_at]
    defstruct [
      :supply_type,
      :quantity,
      :supplier,
      :purchase_order_number,
      :batch_number,
      :expiration_date,
      :storage_location,
      :added_by,
      :added_at
    ]
  end

  defmodule SupplyConsumed do
    @moduledoc "Event raised when supply is consumed."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :quantity, :consumed_at]
    defstruct [
      :supply_type,
      :quantity,
      :consumed_for,
      :crop_id,
      :related_activity,
      :remaining_quantity,
      :consumed_by,
      :consumed_at
    ]
  end

  defmodule SupplyDepleted do
    @moduledoc "Event raised when supply is fully depleted."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :depleted_at]
    defstruct [
      :supply_type,
      :last_known_quantity,
      :impact_on_operations,
      :depletion_warning_issued,
      :depletion_reason,
      :depleted_by,
      :depleted_at
    ]
  end

  defmodule SupplyReplenished do
    @moduledoc "Event raised when supply is replenished."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :quantity, :replenished_at]
    defstruct [
      :supply_type,
      :quantity,
      :previous_quantity,
      :supplier,
      :batch_number,
      :expiration_date,
      :replenishment_order_number,
      :received_by,
      :replenished_at
    ]
  end

  defmodule SupplyReorderTriggered do
    @moduledoc "Event raised when reordering of supply is triggered."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :reorder_quantity, :triggered_at]
    defstruct [
      :supply_type,
      :current_quantity,
      :reorder_quantity,
      :recommended_supplier,
      :reorder_level,
      :urgency,
      :triggered_by,
      :triggered_at
    ]
  end

  defmodule SupplyInspectionScheduled do
    @moduledoc "Event raised when an inspection is scheduled for supplies."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :inspection_scheduled_at]
    defstruct [
      :supply_type,
      :inspection_date,
      :inspector,
      :inspection_type,
      :inspection_reason,
      :inspection_results,
      :inspection_scheduled_at
    ]
  end

  defmodule SupplyInspectionCompleted do
    @moduledoc "Event raised when an inspection of supplies is completed."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :inspection_completed_at]
    defstruct [
      :supply_type,
      :inspection_date,
      :inspector,
      :inspection_results,
      :action_taken,
      :recommendations,
      :inspection_completed_at
    ]
  end

  defmodule SupplyDiscarded do
    @moduledoc "Event raised when supply is discarded due to quality issues."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :discarded_quantity, :discarded_at]
    defstruct [
      :supply_type,
      :discarded_quantity,
      :reason_for_discard,
      :quality_issues,
      :disposed_by,
      :disposal_method,
      :discarded_at
    ]
  end
end 
