defmodule GreenhouseTycoon.MeasureHumidity.HumidityMeasuredToPubSubV1 do
  @moduledoc """
  Projection that handles HumidityMeasured events and broadcasts them to PubSub.
  
  This projection processes humidity measurement events and broadcasts them for subscribers
  like the cache, UI, analytics, etc.
  
  Naming follows the pattern: {event}_to_pubsub_v{version}
  - Event: HumidityMeasured -> humidity_measured
  - Target: PubSub -> pubsub
  """
  
  use Commanded.Event.Handler,
    application: GreenhouseTycoon.CommandedApp,
    name: "humidity_measured_to_pubsub_v1",
    subscribe_to: "$et-humidity_measured:v1"
  
  alias GreenhouseTycoon.MeasureHumidity.EventV1, as: HumidityMeasuredEvent
  alias GreenhouseTycoon.ReadModels.GreenhouseReadModel
  
  require Logger
  
  def handle(%HumidityMeasuredEvent{} = event, _metadata) do
    Logger.info("💧 Processing humidity measurement for greenhouse: #{event.greenhouse_id} - #{event.humidity}%")
    
    read_model = %GreenhouseReadModel{
      greenhouse_id: event.greenhouse_id,
      current_humidity: event.humidity,
      updated_at: event.measured_at
    }
    
    # Broadcast the humidity measurement event
    case Phoenix.PubSub.broadcast(
           GreenhouseTycoon.PubSub,
           "greenhouse_projections",
           {:humidity_measured, read_model}
         ) do
      :ok ->
        Logger.info("✅ Humidity measurement event broadcasted for: #{event.greenhouse_id}")
        :ok
        
      {:error, reason} ->
        Logger.error("❌ Failed to broadcast humidity measurement for: #{event.greenhouse_id}, reason: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
