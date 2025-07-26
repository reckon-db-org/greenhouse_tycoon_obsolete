defmodule GreenhouseTycoon.MeasureHumidity.HumidityMeasuredToAggregateV1 do
  @moduledoc """
  Aggregate event handler for HumidityMeasured events
  """

  alias GreenhouseTycoon.MeasureHumidity.EventV1

  def apply(%GreenhouseTycoon.Greenhouse{} = greenhouse, %EventV1{} = event) do
    %GreenhouseTycoon.Greenhouse{
      greenhouse
      | current_humidity: event.humidity,
        updated_at: event.measured_at
    }
  end
end
