defmodule GreenhouseTycoon.MeasureHumidity.EventV1 do
  @enforce_keys [:greenhouse_id, :humidity, :measured_at]
  defstruct [:greenhouse_id, :humidity, :measured_at]

  def from_command(%GreenhouseTycoon.MeasureHumidity.CommandV1{
        greenhouse_id: greenhouse_id,
        humidity: humidity,
        measured_at: measured_at
      }) do
    %__MODULE__{
      greenhouse_id: greenhouse_id,
      humidity: humidity,
      measured_at: measured_at
    }
  end
end
