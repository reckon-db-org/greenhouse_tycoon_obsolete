defmodule GreenhouseTycoon.MeasureLight.MaybeMeasureLightV1 do
  @moduledoc """
  Command handler for MeasureLight that enforces business rules
  """

  alias GreenhouseTycoon.Aggregate
  alias GreenhouseTycoon.MeasureLight.{CommandV1, EventV1}

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
        %CommandV1{light: light} = _command
      )
      when light < 0 do
    {:error, :invalid_light_value}
  end

  def execute(%Aggregate{} = _greenhouse, %CommandV1{} = command) do
    event = EventV1.from_command(command)
    {:ok, [event]}
  end
end
