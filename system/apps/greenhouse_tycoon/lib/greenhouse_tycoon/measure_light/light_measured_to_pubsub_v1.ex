defmodule GreenhouseTycoon.MeasureLight.LightMeasuredToPubSubV1 do
  @moduledoc """
  Projection that handles LightMeasured events and broadcasts them to PubSub.
  
  This projection processes light measurement events and broadcasts them for subscribers
  like the cache, UI, analytics, etc.
  
  Naming follows the pattern: {event}_to_pubsub_v{version}
  - Event: LightMeasured -> light_measured
  - Target: PubSub -> pubsub
  """
  
  use Commanded.Event.Handler,
    application: GreenhouseTycoon.CommandedApp,
    name: "light_measured_to_pubsub_v1",
    subscribe_to: "$et-light_measured:v1"
  
  alias GreenhouseTycoon.MeasureLight.EventV1, as: LightMeasuredEvent
  alias GreenhouseTycoon.ReadModels.GreenhouseReadModel
  
  require Logger
  
  def handle(%LightMeasuredEvent{} = event, _metadata) do
    Logger.info("💡 Processing light measurement for greenhouse: #{event.greenhouse_id} - #{event.light} lumens")
    
    read_model = %GreenhouseReadModel{
      greenhouse_id: event.greenhouse_id,
      current_light: event.light,
      updated_at: event.measured_at
    }
    
    # Broadcast the light measurement event
    case Phoenix.PubSub.broadcast(
           GreenhouseTycoon.PubSub,
           "greenhouse_projections",
           {:light_measured, read_model}
         ) do
      :ok ->
        Logger.info("✅ Light measurement event broadcasted for: #{event.greenhouse_id}")
        :ok
        
      {:error, reason} ->
        Logger.error("❌ Failed to broadcast light measurement for: #{event.greenhouse_id}, reason: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
