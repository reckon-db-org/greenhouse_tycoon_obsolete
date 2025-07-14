defmodule ManageGreenhouse.Commands do
  @moduledoc """
  Commands for managing greenhouse lifecycle operations.
  """

  defmodule InitializeGreenhouse do
    @moduledoc "Command to initialize a new greenhouse."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :name, :location]
    defstruct [
      :greenhouse_id,
      :name,
      :location,
      :city,
      :country,
      :coordinates,
      :capacity,
      :greenhouse_type,
      :initialized_by
    ]
  end

  defmodule ActivateGreenhouse do
    @moduledoc "Command to activate a greenhouse."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id]
    defstruct [
      :greenhouse_id,
      :activated_by,
      :activation_reason,
      :target_conditions
    ]
  end

  defmodule DeactivateGreenhouse do
    @moduledoc "Command to deactivate a greenhouse."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id]
    defstruct [
      :greenhouse_id,
      :deactivated_by,
      :deactivation_reason
    ]
  end

  defmodule StartGreenhouseSimulation do
    @moduledoc "Command to start simulation for a greenhouse."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id]
    defstruct [
      :greenhouse_id,
      :simulation_config,
      :initial_state,
      :started_by
    ]
  end

  defmodule StopGreenhouseSimulation do
    @moduledoc "Command to stop simulation for a greenhouse."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id]
    defstruct [
      :greenhouse_id,
      :stop_reason,
      :stopped_by
    ]
  end

  defmodule UpdateGreenhouseConfiguration do
    @moduledoc "Command to update greenhouse configuration."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :configuration_changes]
    defstruct [
      :greenhouse_id,
      :configuration_changes,
      :updated_by,
      :update_reason
    ]
  end

  defmodule RetireGreenhouse do
    @moduledoc "Command to retire a greenhouse from service."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :retirement_reason]
    defstruct [
      :greenhouse_id,
      :retirement_reason,
      :archive_data,
      :retired_by
    ]
  end
end
