defmodule GreenhouseTycoon.InitializeGreenhouse.MaybeInitializeGreenhouseV1 do
  @moduledoc """
  Command handler for InitializeGreenhouse command.
  
  Business rules:
  - Greenhouse can be re-initialized to allow state reset
  - Greenhouse must have a name, location, city, and country
  - Target values are optional but must be within valid ranges if provided
  - Temperature: -50°C to 80°C
  - Humidity: 0% to 100%
  - Light: 0 to 100,000 lumens
  """
  
  alias GreenhouseTycoon.Greenhouse
  alias GreenhouseTycoon.InitializeGreenhouse.{CommandV1, EventV1}
  
  require Logger
  
  @doc """
  Executes the InitializeGreenhouse command on a Greenhouse aggregate.
  
  Returns a GreenhouseInitialized event if successful, or an error tuple if not.
  """
  def execute(%Greenhouse{} = _greenhouse, %CommandV1{} = command) do
    Logger.info("MaybeInitializeGreenhouseV1: Initializing greenhouse #{command.greenhouse_id}")
    Logger.debug("MaybeInitializeGreenhouseV1: Command data: #{inspect(command)}")
    
    case CommandV1.valid?(command) do
      :ok ->
        event = EventV1.from_command(command)
        Logger.info("MaybeInitializeGreenhouseV1: Successfully created GreenhouseInitialized event for #{command.greenhouse_id}")
        {:ok, [event]}
      
      {:error, reason} ->
        Logger.error("MaybeInitializeGreenhouseV1: Command validation failed for #{command.greenhouse_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
end
