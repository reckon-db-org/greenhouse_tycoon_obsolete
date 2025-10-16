defmodule GreenhouseTycoon.MeasureHumidity.MaybeMeasureHumidityV1 do
  @moduledoc """
  Command handler for MeasureHumidity that enforces business rules
  """

  alias GreenhouseTycoon.Aggregate
  alias GreenhouseTycoon.MeasureHumidity.{CommandV1, EventV1}

  def execute(%Aggregate{greenhouse_id: nil}, %CommandV1{}) do
    {:error, :greenhouse_not_initialized}
  end

  def execute(
        %Aggregate{greenhouse_id: aggregate_id},
        %CommandV1{greenhouse_id: command_id} = _command
      )
      when aggregate_id != command_id do
    {:error, :greenhouse_id_mismatch}
  end

  def execute(
        %Aggregate{} = _greenhouse,
        %CommandV1{humidity: humidity} = _command
      )
      when humidity < 0 or humidity > 100 do
    {:error, :invalid_humidity_range}
  end

  def execute(%Aggregate{} = _greenhouse, %CommandV1{} = command) do
    event = EventV1.from_command(command)
    {:ok, [event]}
  end
end
