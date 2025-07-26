defmodule GreenhouseTycoon.SetTargetLight.TargetLightSetToPubSubV1 do
  @moduledoc """
  Projection that handles TargetLightSet events and broadcasts them to PubSub.
  
  This projection processes target light set events and broadcasts them for subscribers
  like the cache, UI, analytics, etc.
  
  Naming follows the pattern: {event}_to_pubsub_v{version}
  - Event: TargetLightSet -> target_light_set
  - Target: PubSub -> pubsub
  """
  
  use Commanded.Event.Handler,
    application: GreenhouseTycoon.CommandedApp,
    name: "target_light_set_to_pubsub_v1",
    subscribe_to: "$et-target_light_set:v1"
  
  alias GreenhouseTycoon.SetTargetLight.EventV1, as: TargetLightSetEvent
  alias GreenhouseTycoon.ReadModels.GreenhouseReadModel
  
  require Logger
  
  def handle(%TargetLightSetEvent{} = event, _metadata) do
    Logger.info("💡 Processing target light set for greenhouse: #{event.greenhouse_id} to #{event.target_light} lumens")
    
    read_model = %GreenhouseReadModel{
      greenhouse_id: event.greenhouse_id,
      target_light: event.target_light,
      updated_at: event.set_at
    }
    
    # Broadcast the target light set event
    case Phoenix.PubSub.broadcast(
           GreenhouseTycoon.PubSub,
           "greenhouse_projections",
           {:target_light_set, read_model}
         ) do
      :ok ->
        Logger.info("✅ Target light set event broadcasted for: #{event.greenhouse_id}")
        :ok
        
      {:error, reason} ->
        Logger.error("❌ Failed to broadcast target light set for: #{event.greenhouse_id}, reason: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
