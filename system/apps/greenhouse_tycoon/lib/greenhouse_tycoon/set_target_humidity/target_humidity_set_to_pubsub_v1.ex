defmodule GreenhouseTycoon.SetTargetHumidity.TargetHumiditySetToPubSubV1 do
  @moduledoc """
  Projection that handles TargetHumiditySet events and broadcasts them to PubSub.
  
  This projection processes target humidity set events and broadcasts them for subscribers
  like the cache, UI, analytics, etc.
  
  Naming follows the pattern: {event}_to_pubsub_v{version}
  - Event: TargetHumiditySet -> target_humidity_set
  - Target: PubSub -> pubsub
  """
  
  use Commanded.Event.Handler,
    application: GreenhouseTycoon.CommandedApp,
    name: "target_humidity_set_to_pubsub_v1",
    subscribe_to: "$et-target_humidity_set:v1"
  
  alias GreenhouseTycoon.SetTargetHumidity.EventV1, as: TargetHumiditySetEvent
  alias GreenhouseTycoon.ReadModels.GreenhouseReadModel
  
  require Logger
  
  def handle(%TargetHumiditySetEvent{} = event, _metadata) do
    Logger.info("💧 Processing target humidity set for greenhouse: #{event.greenhouse_id} to #{event.target_humidity}%")
    
    read_model = %GreenhouseReadModel{
      greenhouse_id: event.greenhouse_id,
      target_humidity: event.target_humidity,
      updated_at: event.set_at
    }
    
    # Broadcast the target humidity set event
    case Phoenix.PubSub.broadcast(
           GreenhouseTycoon.PubSub,
           "greenhouse_projections",
           {:target_humidity_set, read_model}
         ) do
      :ok ->
        Logger.info("✅ Target humidity set event broadcasted for: #{event.greenhouse_id}")
        :ok
        
      {:error, reason} ->
        Logger.error("❌ Failed to broadcast target humidity set for: #{event.greenhouse_id}, reason: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
