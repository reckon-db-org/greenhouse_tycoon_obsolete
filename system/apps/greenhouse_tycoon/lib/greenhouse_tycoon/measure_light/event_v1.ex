defmodule GreenhouseTycoon.MeasureLight.EventV1 do
  @enforce_keys [:greenhouse_id, :light, :measured_at]
  defstruct [:greenhouse_id, :light, :measured_at]

  def from_command(%GreenhouseTycoon.MeasureLight.CommandV1{
        greenhouse_id: greenhouse_id,
        light: light,
        measured_at: measured_at
      }) do
    %__MODULE__{
      greenhouse_id: greenhouse_id,
      light: light,
      measured_at: measured_at
    }
  end
end
