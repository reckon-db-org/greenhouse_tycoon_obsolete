defmodule GreenhouseTycoon.SetTargetLight.EventV1 do
  @moduledoc """
  Event emitted when target light level is successfully set for a greenhouse.
  
  This event contains information about the light change including
  the previous value for audit purposes.
  """
  
  @derive Jason.Encoder
  defstruct [
    :greenhouse_id,
    :target_light,
    :previous_target_light,
    :set_by,
    :set_at,
    :version
  ]
  
  @type t :: %__MODULE__{
    greenhouse_id: String.t(),
    target_light: float(),
    previous_target_light: float() | nil,
    set_by: String.t() | nil,
    set_at: DateTime.t(),
    version: integer()
  }
  
  @doc """
  Creates a new TargetLightSet event from a command and current greenhouse state.
  """
  def from_command(%GreenhouseTycoon.SetTargetLight.CommandV1{} = command, previous_target_light) do
    %__MODULE__{
      greenhouse_id: command.greenhouse_id,
      target_light: command.target_light,
      previous_target_light: previous_target_light,
      set_by: command.set_by,
      set_at: command.requested_at,
      version: 1
    }
  end
  
  @doc """
  Gets the event type string for storage.
  """
  def event_type, do: "target_light_set:v1"
end
