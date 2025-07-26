defmodule GreenhouseTycoon.SetTargetTemperature.EventV1 do
  @moduledoc """
  Event emitted when target temperature is successfully set for a greenhouse.
  
  This event contains information about the temperature change including
  the previous value for audit purposes.
  """
  
  @derive Jason.Encoder
  defstruct [
    :greenhouse_id,
    :target_temperature,
    :previous_target_temperature,
    :set_by,
    :set_at,
    :version
  ]
  
  @type t :: %__MODULE__{
    greenhouse_id: String.t(),
    target_temperature: float(),
    previous_target_temperature: float() | nil,
    set_by: String.t() | nil,
    set_at: DateTime.t(),
    version: integer()
  }
  
  @doc """
  Creates a new TargetTemperatureSet event from a command and current greenhouse state.
  """
  def from_command(%GreenhouseTycoon.SetTargetTemperature.CommandV1{} = command, previous_target_temperature) do
    %__MODULE__{
      greenhouse_id: command.greenhouse_id,
      target_temperature: command.target_temperature,
      previous_target_temperature: previous_target_temperature,
      set_by: command.set_by,
      set_at: command.requested_at,
      version: 1
    }
  end
  
  @doc """
  Gets the event type string for storage.
  """
  def event_type, do: "target_temperature_set:v1"
end
