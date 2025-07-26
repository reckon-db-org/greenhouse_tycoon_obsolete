defmodule GreenhouseTycoon.InitializeGreenhouse.EventV1 do
  @moduledoc """
  Event emitted when a greenhouse is successfully initialized.
  
  This event contains all the information needed to track the greenhouse's
  creation and triggers read model updates and other domain reactions.
  """
  
  @derive Jason.Encoder
  defstruct [
    :greenhouse_id,
    :name,
    :location,
    :city,
    :country,
    :target_temperature,
    :target_humidity,
    :target_light,
    :initialized_at,
    :version
  ]
  
  @type t :: %__MODULE__{
    greenhouse_id: String.t(),
    name: String.t(),
    location: String.t(),
    city: String.t(),
    country: String.t(),
    target_temperature: float() | nil,
    target_humidity: float() | nil,
    target_light: float() | nil,
    initialized_at: DateTime.t(),
    version: integer()
  }
  
  @doc """
  Creates a new GreenhouseInitialized event from a command.
  """
  def from_command(%GreenhouseTycoon.InitializeGreenhouse.CommandV1{} = command) do
    %__MODULE__{
      greenhouse_id: command.greenhouse_id,
      name: command.name,
      location: command.location,
      city: command.city,
      country: command.country,
      target_temperature: command.target_temperature,
      target_humidity: command.target_humidity,
      target_light: command.target_light,
      initialized_at: command.requested_at,
      version: 1
    }
  end
  
  @doc """
  Gets the event type string for storage.
  """
  def event_type, do: "greenhouse_initialized:v1"
end

