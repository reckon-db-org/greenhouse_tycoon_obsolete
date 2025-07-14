defmodule SimulateCrops.Events do
  @moduledoc """
  Events emitted by the crop simulation system.
  """

  defmodule CropSimulationStarted do
    @moduledoc "Event raised when crop simulation starts for a greenhouse."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :crop_id, :crop_type, :started_at]
    defstruct [
      :greenhouse_id,
      :crop_id,
      :crop_type,
      :started_at
    ]
  end

  defmodule CropGrowthProgressed do
    @moduledoc "Event raised when crop growth progresses."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :crop_id, :growth_stage, :growth_progress, :health_status, :progressed_at]
    defstruct [
      :greenhouse_id,
      :crop_id,
      :growth_stage,
      :growth_progress,
      :health_status,
      :progressed_at
    ]
  end

  defmodule CropReadyForHarvest do
    @moduledoc "Event raised when crop is ready for harvest."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :crop_id, :crop_type, :estimated_yield, :ready_at]
    defstruct [
      :greenhouse_id,
      :crop_id,
      :crop_type,
      :estimated_yield,
      :ready_at
    ]
  end

  defmodule CropSimulationStopped do
    @moduledoc "Event raised when crop simulation stops."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :crop_id, :final_state, :stopped_at]
    defstruct [
      :greenhouse_id,
      :crop_id,
      :final_state,
      :stopped_at
    ]
  end
end
