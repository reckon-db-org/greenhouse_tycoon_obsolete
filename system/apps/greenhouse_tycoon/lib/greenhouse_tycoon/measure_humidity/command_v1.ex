defmodule GreenhouseTycoon.MeasureHumidity.CommandV1 do
  @enforce_keys [:greenhouse_id, :humidity, :measured_at]
  defstruct [:greenhouse_id, :humidity, :measured_at]

  def new(attrs) do
    {:ok, struct!(__MODULE__, attrs)}
  end
end
