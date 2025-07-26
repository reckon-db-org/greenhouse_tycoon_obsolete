defmodule GreenhouseTycoon.SetTargetTemperature.MaybeSetTargetTemperatureV1 do
  @moduledoc """
  Command handler for SetTargetTemperature command.
  
  Business rules:
  - Greenhouse must already exist (cannot set temperature on non-existent greenhouse)
  - Target temperature must be within valid range (-50°C to 80°C)
  - Command greenhouse_id must match aggregate greenhouse_id
  """
  
  alias GreenhouseTycoon.Greenhouse
  alias GreenhouseTycoon.SetTargetTemperature.{CommandV1, EventV1}
  
  require Logger
  
  @doc """
  Executes the SetTargetTemperature command on a Greenhouse aggregate.
  
  Returns a TargetTemperatureSet event if successful, or an error tuple if not.
  """
  def execute(%Greenhouse{greenhouse_id: nil}, %CommandV1{greenhouse_id: greenhouse_id}) do
    Logger.error("MaybeSetTargetTemperatureV1: Cannot set temperature for non-existent greenhouse: #{greenhouse_id}")
    {:error, :greenhouse_not_found}
  end
  
  def execute(%Greenhouse{greenhouse_id: greenhouse_id} = greenhouse, %CommandV1{greenhouse_id: greenhouse_id} = command) do
    Logger.info("MaybeSetTargetTemperatureV1: Setting temperature for greenhouse #{greenhouse_id} to #{command.target_temperature}°C")
    Logger.debug("MaybeSetTargetTemperatureV1: Command data: #{inspect(command)}")
    
    case CommandV1.valid?(command) do
      :ok ->
        event = EventV1.from_command(command, greenhouse.target_temperature)
        Logger.info("MaybeSetTargetTemperatureV1: Successfully created TargetTemperatureSet event for #{greenhouse_id}")
        {:ok, [event]}
      
      {:error, reason} ->
        Logger.error("MaybeSetTargetTemperatureV1: Command validation failed for #{greenhouse_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  def execute(%Greenhouse{greenhouse_id: existing_id}, %CommandV1{greenhouse_id: command_id}) do
    Logger.error("MaybeSetTargetTemperatureV1: Greenhouse ID mismatch - existing: #{existing_id}, command: #{command_id}")
    {:error, :greenhouse_id_mismatch}
  end
end
