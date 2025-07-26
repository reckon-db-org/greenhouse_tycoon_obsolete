defmodule GreenhouseTycoon.SetTargetHumidity.EventV1 do
  @moduledoc """
  Event emitted when target humidity is successfully set for a greenhouse.
  
  This event contains information about the humidity change including
  the previous value for audit purposes.
  """
  
  @derive Jason.Encoder
  defstruct [
    :greenhouse_id,
    :target_humidity,
    :previous_target_humidity,
    :set_by,
    :set_at,
    :version
  ]
  
  @type t :: %__MODULE__{
    greenhouse_id: String.t(),
    target_humidity: float(),
    previous_target_humidity: float() | nil,
    set_by: String.t() | nil,
    set_at: DateTime.t(),
    version: integer()
  }
  
  @doc """
  Creates a new TargetHumiditySet event from a command and current greenhouse state.
  """
  def from_command(%GreenhouseTycoon.SetTargetHumidity.CommandV1{} = command, previous_target_humidity) do
    %__MODULE__{
      greenhouse_id: command.greenhouse_id,
      target_humidity: command.target_humidity,
      previous_target_humidity: previous_target_humidity,
      set_by: command.set_by,
      set_at: command.requested_at,
      version: 1
    }
  end
  
  @doc """
  Gets the event type string for storage.
  """
  def event_type, do: "target_humidity_set:v1"
end
