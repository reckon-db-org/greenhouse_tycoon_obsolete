defmodule GreenhouseTycoon.SetTargetHumidity.MaybeSetTargetHumidityV1 do
  @moduledoc """
  Command handler for SetTargetHumidity command.
  
  Business rules:
  - Greenhouse must already exist (cannot set humidity on non-existent greenhouse)
  - Target humidity must be within valid range (0% to 100%)
  - Command greenhouse_id must match aggregate greenhouse_id
  """
  
  alias GreenhouseTycoon.Greenhouse
  alias GreenhouseTycoon.SetTargetHumidity.{CommandV1, EventV1}
  
  require Logger
  
  @doc """
  Executes the SetTargetHumidity command on a Greenhouse aggregate.
  
  Returns a TargetHumiditySet event if successful, or an error tuple if not.
  """
  def execute(%Greenhouse{greenhouse_id: nil}, %CommandV1{greenhouse_id: greenhouse_id}) do
    Logger.error("MaybeSetTargetHumidityV1: Cannot set humidity for non-existent greenhouse: #{greenhouse_id}")
    {:error, :greenhouse_not_found}
  end
  
  def execute(%Greenhouse{greenhouse_id: greenhouse_id} = greenhouse, %CommandV1{greenhouse_id: greenhouse_id} = command) do
    Logger.info("MaybeSetTargetHumidityV1: Setting humidity for greenhouse #{greenhouse_id} to #{command.target_humidity}%")
    Logger.debug("MaybeSetTargetHumidityV1: Command data: #{inspect(command)}")
    
    case CommandV1.valid?(command) do
      :ok ->
        event = EventV1.from_command(command, greenhouse.target_humidity)
        Logger.info("MaybeSetTargetHumidityV1: Successfully created TargetHumiditySet event for #{greenhouse_id}")
        {:ok, [event]}
      
      {:error, reason} ->
        Logger.error("MaybeSetTargetHumidityV1: Command validation failed for #{greenhouse_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  def execute(%Greenhouse{greenhouse_id: existing_id}, %CommandV1{greenhouse_id: command_id}) do
    Logger.error("MaybeSetTargetHumidityV1: Greenhouse ID mismatch - existing: #{existing_id}, command: #{command_id}")
    {:error, :greenhouse_id_mismatch}
  end
end
