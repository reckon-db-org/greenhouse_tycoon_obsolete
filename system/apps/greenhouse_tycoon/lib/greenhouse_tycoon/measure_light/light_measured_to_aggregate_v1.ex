defmodule GreenhouseTycoon.MeasureLight.LightMeasuredToAggregateV1 do
  @moduledoc """
  Aggregate event handler for LightMeasured events
  """

  alias GreenhouseTycoon.MeasureLight.EventV1

  def apply(%GreenhouseTycoon.Greenhouse{} = greenhouse, %EventV1{} = event) do
    %GreenhouseTycoon.Greenhouse{
      greenhouse
      | current_light: event.light,
        updated_at: event.measured_at
    }
  end
end
