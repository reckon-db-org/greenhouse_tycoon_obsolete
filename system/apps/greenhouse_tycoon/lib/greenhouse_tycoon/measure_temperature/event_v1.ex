defmodule GreenhouseTycoon.MeasureTemperature.EventV1 do
  @moduledoc """
  Event emitted when a temperature measurement is successfully recorded for a greenhouse.
  
  This event contains the measurement information and metadata about how
  the measurement was taken.
  """
  
  @derive Jason.Encoder
  defstruct [
    :greenhouse_id,
    :temperature,
    :measured_at,
    :sensor_id,
    :measurement_type,
    :version
  ]
  
  @type measurement_type :: :sensor | :manual
  
  @type t :: %__MODULE__{
    greenhouse_id: String.t(),
    temperature: float(),
    measured_at: DateTime.t(),
    sensor_id: String.t() | nil,
    measurement_type: measurement_type(),
    version: integer()
  }
  
  @doc """
  Creates a new TemperatureMeasured event from a command.
  """
  def from_command(%GreenhouseTycoon.MeasureTemperature.CommandV1{} = command) do
    %__MODULE__{
      greenhouse_id: command.greenhouse_id,
      temperature: command.temperature,
      measured_at: command.measured_at,
      sensor_id: command.sensor_id,
      measurement_type: command.measurement_type,
      version: 1
    }
  end
  
  @doc """
  Gets the event type string for storage.
  """
  def event_type, do: "temperature_measured:v1"
end
