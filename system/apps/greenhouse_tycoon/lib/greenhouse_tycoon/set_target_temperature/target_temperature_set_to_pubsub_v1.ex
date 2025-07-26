defmodule GreenhouseTycoon.SetTargetTemperature.TargetTemperatureSetToPubSubV1 do
  @moduledoc """
  Projection that handles TargetTemperatureSet events and broadcasts them to PubSub.
  
  This projection processes target temperature set events and broadcasts them for subscribers
  like the cache, UI, analytics, etc.
  
  Naming follows the pattern: {event}_to_pubsub_v{version}
  - Event: TargetTemperatureSet -> target_temperature_set
  - Target: PubSub -> pubsub
  """
  
  use Commanded.Event.Handler,
    application: GreenhouseTycoon.CommandedApp,
    name: "target_temperature_set_to_pubsub_v1",
    subscribe_to: "$et-target_temperature_set:v1"
  
  alias GreenhouseTycoon.SetTargetTemperature.EventV1, as: TargetTemperatureSetEvent
  alias GreenhouseTycoon.ReadModels.GreenhouseReadModel
  
  require Logger
  
  def handle(%TargetTemperatureSetEvent{} = event, _metadata) do
    Logger.info("🌡️  Processing target temperature set for greenhouse: #{event.greenhouse_id} to #{event.target_temperature}°C")
    
    read_model = %GreenhouseReadModel{
      greenhouse_id: event.greenhouse_id,
      target_temperature: event.target_temperature,
      updated_at: event.set_at
    }
    
    # Broadcast the target temperature set event
    case Phoenix.PubSub.broadcast(
           GreenhouseTycoon.PubSub,
           "greenhouse_projections",
           {:target_temperature_set, read_model}
         ) do
      :ok ->
        Logger.info("✅ Target temperature set event broadcasted for: #{event.greenhouse_id}")
        :ok
        
      {:error, reason} ->
        Logger.error("❌ Failed to broadcast target temperature set for: #{event.greenhouse_id}, reason: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
