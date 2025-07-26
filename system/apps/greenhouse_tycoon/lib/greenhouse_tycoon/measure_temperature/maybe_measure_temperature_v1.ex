defmodule GreenhouseTycoon.MeasureTemperature.MaybeMeasureTemperatureV1 do
  @moduledoc """
  Command handler for MeasureTemperature command.
  
  Business rules:
  - Greenhouse must already exist (cannot measure temperature on non-existent greenhouse)
  - Temperature must be within valid range (-100°C to 100°C)
  - Measurement timestamp must be valid
  - Command greenhouse_id must match aggregate greenhouse_id
  """
  
  alias GreenhouseTycoon.Greenhouse
  alias GreenhouseTycoon.MeasureTemperature.{CommandV1, EventV1}
  
  require Logger
  
  @doc """
  Executes the MeasureTemperature command on a Greenhouse aggregate.
  
  Returns a TemperatureMeasured event if successful, or an error tuple if not.
  """
  def execute(%Greenhouse{greenhouse_id: nil}, %CommandV1{greenhouse_id: greenhouse_id}) do
    Logger.error("MaybeMeasureTemperatureV1: Cannot measure temperature for non-existent greenhouse: #{greenhouse_id}")
    {:error, :greenhouse_not_found}
  end
  
  def execute(%Greenhouse{greenhouse_id: greenhouse_id} = _greenhouse, %CommandV1{greenhouse_id: greenhouse_id} = command) do
    Logger.info("MaybeMeasureTemperatureV1: Recording temperature measurement for greenhouse #{greenhouse_id}: #{command.temperature}°C")
    Logger.debug("MaybeMeasureTemperatureV1: Command data: #{inspect(command)}")
    
    case CommandV1.valid?(command) do
      :ok ->
        event = EventV1.from_command(command)
        Logger.info("MaybeMeasureTemperatureV1: Successfully created TemperatureMeasured event for #{greenhouse_id}")
        {:ok, [event]}
      
      {:error, reason} ->
        Logger.error("MaybeMeasureTemperatureV1: Command validation failed for #{greenhouse_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  def execute(%Greenhouse{greenhouse_id: existing_id}, %CommandV1{greenhouse_id: command_id}) do
    Logger.error("MaybeMeasureTemperatureV1: Greenhouse ID mismatch - existing: #{existing_id}, command: #{command_id}")
    {:error, :greenhouse_id_mismatch}
  end
end
