defmodule ManageGreenhouse.Events do
  @moduledoc """
  Events for greenhouse lifecycle management.
  """

  defmodule GreenhouseInitialized do
    @moduledoc "Event raised when a greenhouse is initialized."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :name, :location, :initialized_at]
    defstruct [
      :greenhouse_id,
      :name,
      :location,
      :city,
      :country,
      :coordinates,
      :capacity,
      :greenhouse_type,
      :initialized_by,
      :initialized_at
    ]
  end

  defmodule GreenhouseActivated do
    @moduledoc "Event raised when a greenhouse is activated."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :activated_at]
    defstruct [
      :greenhouse_id,
      :activated_by,
      :activation_reason,
      :target_conditions,
      :activated_at
    ]
  end

  defmodule GreenhouseDeactivated do
    @moduledoc "Event raised when a greenhouse is deactivated."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :deactivated_at]
    defstruct [
      :greenhouse_id,
      :deactivated_by,
      :deactivation_reason,
      :final_conditions,
      :deactivated_at
    ]
  end

  defmodule GreenhouseSimulationStarted do
    @moduledoc "Event raised when simulation is started for a greenhouse."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :simulation_started_at]
    defstruct [
      :greenhouse_id,
      :simulation_config,
      :initial_state,
      :started_by,
      :simulation_started_at
    ]
  end

  defmodule GreenhouseSimulationStopped do
    @moduledoc "Event raised when simulation is stopped for a greenhouse."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :simulation_stopped_at]
    defstruct [
      :greenhouse_id,
      :stop_reason,
      :final_state,
      :simulation_duration,
      :stopped_by,
      :simulation_stopped_at
    ]
  end

  defmodule GreenhouseConfigurationUpdated do
    @moduledoc "Event raised when greenhouse configuration is updated."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :configuration_changes, :updated_at]
    defstruct [
      :greenhouse_id,
      :configuration_changes,
      :previous_configuration,
      :updated_by,
      :update_reason,
      :updated_at
    ]
  end

  defmodule GreenhouseRetired do
    @moduledoc "Event raised when a greenhouse is retired from service."
    
    @derive Jason.Encoder
    @enforce_keys [:greenhouse_id, :retired_at]
    defstruct [
      :greenhouse_id,
      :retirement_reason,
      :final_status,
      :archived_data,
      :retired_by,
      :retired_at
    ]
  end
end
