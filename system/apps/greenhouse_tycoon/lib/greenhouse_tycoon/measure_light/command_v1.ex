defmodule GreenhouseTycoon.MeasureLight.CommandV1 do
  @enforce_keys [:greenhouse_id, :light, :measured_at]
  defstruct [:greenhouse_id, :light, :measured_at]

  def new(attrs) do
    {:ok, struct!(__MODULE__, attrs)}
  end
end
