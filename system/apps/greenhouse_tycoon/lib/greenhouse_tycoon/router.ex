defmodule GreenhouseTycoon.Router do
  @moduledoc """
  Command router for GreenhouseTycoon.

  This router defines how commands are dispatched to aggregates
  in the greenhouse regulation domain using vertical slice architecture.
  """

  use Commanded.Commands.Router

  middleware(GreenhouseTycoon.Middleware.LoggingMiddleware)

  alias GreenhouseTycoon.Aggregate

  # Import vertical slice command modules
  alias GreenhouseTycoon.InitializeGreenhouse.CommandV1, as: InitializeGreenhouseV1
  alias GreenhouseTycoon.SetTargetTemperature.CommandV1, as: SetTargetTemperatureV1
  alias GreenhouseTycoon.SetTargetHumidity.CommandV1, as: SetTargetHumidityV1
  alias GreenhouseTycoon.SetTargetLight.CommandV1, as: SetTargetLightV1
  alias GreenhouseTycoon.MeasureTemperature.CommandV1, as: MeasureTemperatureV1
  alias GreenhouseTycoon.MeasureHumidity.CommandV1, as: MeasureHumidityV1
  alias GreenhouseTycoon.MeasureLight.CommandV1, as: MeasureLightV1

  # Route commands to the Aggregate
  identify(Aggregate, by: :greenhouse_id)

  dispatch(
    [
      InitializeGreenhouseV1,
      SetTargetTemperatureV1,
      SetTargetHumidityV1,
      SetTargetLightV1,
      MeasureTemperatureV1,
      MeasureHumidityV1,
      MeasureLightV1
    ],
    to: Aggregate
  )
end
