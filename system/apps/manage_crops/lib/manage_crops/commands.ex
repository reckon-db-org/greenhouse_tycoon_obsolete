defmodule ManageCrops.Commands do
  @moduledoc """
  Commands for crop management operations.
  """

  defmodule PlantCrop do
    @moduledoc "Command to plant a new crop."
    
    @derive Jason.Encoder
    @enforce_keys [:crop_id, :greenhouse_id, :crop_type]
    defstruct [:crop_id, :greenhouse_id, :crop_type, :planted_by, :expected_harvest_date]
  end

  defmodule UpdateCropGrowth do
    @moduledoc "Command to update crop growth information."
    
    @derive Jason.Encoder
    @enforce_keys [:crop_id, :growth_stage]
    defstruct [:crop_id, :growth_stage, :health_status, :updated_by]
  end

  defmodule MarkCropReadyForHarvest do
    @moduledoc "Command to mark a crop as ready for harvest."
    
    @derive Jason.Encoder
    @enforce_keys [:crop_id]
    defstruct [:crop_id, :yield_estimation, :marked_by]
  end

  defmodule HarvestCrop do
    @moduledoc "Command to harvest a crop."
    
    @derive Jason.Encoder
    @enforce_keys [:crop_id]
    defstruct [:crop_id, :harvested_by, :actual_yield]
  end
end
