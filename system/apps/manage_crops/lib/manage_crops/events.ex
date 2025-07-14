defmodule ManageCrops.Events do
  @moduledoc """
  Events specific to crop management within the greenhouse.
  """

  defmodule CropPlanted do
    @moduledoc "Event raised when a crop is planted."
    
    @derive Jason.Encoder
    @enforce_keys [:crop_id, :greenhouse_id, :planted_at]
    defstruct [:crop_id, :greenhouse_id, :crop_type, :planted_at, :expected_harvest_date]
  end

  defmodule CropGrowthUpdated do
    @moduledoc "Event raised when crop growth is updated."
    
    @derive Jason.Encoder
    @enforce_keys [:crop_id, :growth_stage]
    defstruct [:crop_id, :growth_stage, :health_status, :updated_at]
  end

  defmodule CropHarvestReady do
    @moduledoc "Event raised when a crop is ready for harvest."
    
    @derive Jason.Encoder
    @enforce_keys [:crop_id, :ready_at]
    defstruct [:crop_id, :yield_estimation, :ready_at]
  end

  defmodule CropHarvested do
    @moduledoc "Event raised when a crop is harvested."
    
    @derive Jason.Encoder
    @enforce_keys [:crop_id, :harvested_at]
    defstruct [:crop_id, :actual_yield, :harvested_at]
  end
end

