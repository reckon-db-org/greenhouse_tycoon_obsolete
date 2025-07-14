defmodule GreenhouseTycoon.Router do
  @moduledoc """
  Command router for GreenhouseTycoon.

  This router defines how commands are dispatched to aggregates
  in the greenhouse regulation domain.
  """

  use Commanded.Commands.Router

  middleware(GreenhouseTycoon.Middleware.LoggingMiddleware)

  alias GreenhouseTycoon.Greenhouse

  alias GreenhouseTycoon.Commands.{
    InitializeGreenhouse,
    SetTemperature,
    SetHumidity,
    SetLight,
    MeasureTemperature,
    MeasureHumidity,
    MeasureLight
  }

  # Route commands to the Greenhouse aggregate
  identify(Greenhouse, by: :greenhouse_id)

  dispatch(
    [
      InitializeGreenhouse,
      SetTemperature,
      SetHumidity,
      SetLight,
      MeasureTemperature,
      MeasureHumidity,
      MeasureLight
    ],
    to: Greenhouse
  )
end
