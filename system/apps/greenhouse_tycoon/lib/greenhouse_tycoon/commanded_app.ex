defmodule GreenhouseTycoon.CommandedApp do
  @moduledoc """
  Commanded application for GreenhouseTycoon.
  
  This module defines the Commanded application that uses the ExESDB.Commanded.Adapter
  for event sourcing with EventStore DB via the ExESDB Gater.
  """

  use Commanded.Application,
    otp_app: :greenhouse_tycoon,
    event_store: [
      adapter: ExESDB.Commanded.Adapter,
      store_id: :greenhouse_tycoon,
      stream_prefix: "greenhouse_tycoon_",
      serializer: Jason,
      event_type_mapper: GreenhouseTycoon.EventTypeMapper
    ],
    pubsub: [
      phoenix_pubsub: [
        name: GreenhouseTycoon.PubSub
      ]
    ],
    # Enable automatic subscriptions for proper event sourcing
    subscribe_to_all_streams?: true,
    
    # Enable snapshots for fast aggregate recovery
    snapshot_store: ExESDB.Commanded.Adapter.SnapshotStore,
    
    # Configure snapshot frequency (every 100 events)
    snapshot_version: 1

  # Configure the event store adapter for command dispatch only
  router(GreenhouseTycoon.Router)
  
  @doc """
  Wrapper for Commanded.Application.dispatch/2 with logging.
  """
  def dispatch_command(command, opts \\ []) do
    require Logger
    command_name = command.__struct__ |> to_string() |> String.split(".") |> List.last()
    
    Logger.info("CommandedApp: Dispatching #{command_name} command: #{inspect(command)}")
    
    case Commanded.Application.dispatch(__MODULE__, command, opts) do
      :ok -> 
        Logger.info("CommandedApp: Successfully dispatched #{command_name} command")
        :ok
      {:error, reason} = error -> 
        Logger.error("CommandedApp: Failed to dispatch #{command_name} command: #{inspect(reason)}")
        error
    end
  end
end
