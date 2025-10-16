defmodule GreenhouseTycoon.SetTargetLight.MaybeSetTargetLightV1 do
  @moduledoc """
  Command handler for SetTargetLight command.
  
  Business rules:
  - Greenhouse must already exist (cannot set light on non-existent greenhouse)
  - Target light must be within valid range (0 to 100,000 lumens)
  - Command greenhouse_id must match aggregate greenhouse_id
  """
  
  alias GreenhouseTycoon.Aggregate
  alias GreenhouseTycoon.SetTargetLight.{CommandV1, EventV1}
  
  require Logger
  
  @doc """
  Executes the SetTargetLight command on a Greenhouse aggregate.
  
  Returns a TargetLightSet event if successful, or an error tuple if not.
  """
  def execute(%Aggregate{greenhouse_id: nil}, %CommandV1{greenhouse_id: greenhouse_id}) do
    Logger.error("MaybeSetTargetLightV1: Cannot set light for non-existent greenhouse: #{greenhouse_id}")
    {:error, :greenhouse_not_found}
  end
  
  def execute(%Aggregate{greenhouse_id: greenhouse_id} = greenhouse, %CommandV1{greenhouse_id: greenhouse_id} = command) do
    Logger.info("MaybeSetTargetLightV1: Setting light for greenhouse #{greenhouse_id} to #{command.target_light} lumens")
    Logger.debug("MaybeSetTargetLightV1: Command data: #{inspect(command)}")
    
    case CommandV1.valid?(command) do
      :ok ->
        event = EventV1.from_command(command, greenhouse.target_light)
        Logger.info("MaybeSetTargetLightV1: Successfully created TargetLightSet event for #{greenhouse_id}")
        {:ok, [event]}
      
      {:error, reason} ->
        Logger.error("MaybeSetTargetLightV1: Command validation failed for #{greenhouse_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  def execute(%Aggregate{greenhouse_id: existing_id}, %CommandV1{greenhouse_id: command_id}) do
    Logger.error("MaybeSetTargetLightV1: Greenhouse ID mismatch - existing: #{existing_id}, command: #{command_id}")
    {:error, :greenhouse_id_mismatch}
  end
end
