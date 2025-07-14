defmodule ProcureSupplies.Commands do
  @moduledoc """
  Commands for managing supply inventory and procurement operations.
  """

  defmodule AddSupply do
    @moduledoc "Command to add supply to inventory."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :quantity]
    defstruct [
      :supply_type,
      :quantity,
      :supplier,
      :purchase_order_number,
      :batch_number,
      :expiration_date,
      :storage_location,
      :added_by
    ]
  end

  defmodule ConsumeSupply do
    @moduledoc "Command to consume supply from inventory."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :quantity]
    defstruct [
      :supply_type,
      :quantity,
      :consumed_for,
      :crop_id,
      :related_activity,
      :consumed_by
    ]
  end

  defmodule ReplenishSupply do
    @moduledoc "Command to replenish supply inventory."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :quantity]
    defstruct [
      :supply_type,
      :quantity,
      :supplier,
      :batch_number,
      :expiration_date,
      :replenishment_order_number,
      :received_by
    ]
  end

  defmodule TriggerSupplyReorder do
    @moduledoc "Command to trigger reordering of supply."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :reorder_quantity]
    defstruct [
      :supply_type,
      :current_quantity,
      :reorder_quantity,
      :recommended_supplier,
      :reorder_level,
      :urgency,
      :triggered_by
    ]
  end

  defmodule ScheduleSupplyInspection do
    @moduledoc "Command to schedule an inspection for supplies."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :inspection_date]
    defstruct [
      :supply_type,
      :inspection_date,
      :inspector,
      :inspection_type,
      :inspection_reason
    ]
  end

  defmodule CompleteSupplyInspection do
    @moduledoc "Command to complete an inspection of supplies."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :inspection_results]
    defstruct [
      :supply_type,
      :inspection_date,
      :inspector,
      :inspection_results,
      :action_taken,
      :recommendations
    ]
  end

  defmodule DiscardSupply do
    @moduledoc "Command to discard supply due to quality issues."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :discarded_quantity, :reason_for_discard]
    defstruct [
      :supply_type,
      :discarded_quantity,
      :reason_for_discard,
      :quality_issues,
      :disposed_by,
      :disposal_method
    ]
  end

  defmodule CheckSupplyLevels do
    @moduledoc "Command to check supply levels for all supplies."
    
    @derive Jason.Encoder
    @enforce_keys [:checked_by]
    defstruct [
      :checked_by,
      :check_type,
      :specific_supplies
    ]
  end

  defmodule UpdateSupplyReorderLevel do
    @moduledoc "Command to update the reorder level for a supply."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :new_reorder_level]
    defstruct [
      :supply_type,
      :new_reorder_level,
      :previous_reorder_level,
      :reason_for_change,
      :updated_by
    ]
  end

  defmodule TransferSupply do
    @moduledoc "Command to transfer supply between storage locations."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :quantity, :from_location, :to_location]
    defstruct [
      :supply_type,
      :quantity,
      :from_location,
      :to_location,
      :transfer_reason,
      :transferred_by
    ]
  end

  defmodule AdjustSupplyQuantity do
    @moduledoc "Command to adjust supply quantity (e.g., for inventory corrections)."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :adjustment_quantity, :adjustment_type]
    defstruct [
      :supply_type,
      :adjustment_quantity,
      :adjustment_type,
      :adjustment_reason,
      :adjusted_by
    ]
  end

  defmodule SetSupplyExpiration do
    @moduledoc "Command to set or update supply expiration date."
    
    @derive Jason.Encoder
    @enforce_keys [:supply_type, :expiration_date]
    defstruct [
      :supply_type,
      :batch_number,
      :expiration_date,
      :previous_expiration_date,
      :updated_by
    ]
  end
end
