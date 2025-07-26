defmodule GreenhouseTycoon.MeasureTemperature.TemperatureMeasuredToPubSubV1 do
  @moduledoc """
  Projection that handles TemperatureMeasured events and broadcasts them to PubSub.
  
  This projection processes temperature measurement events and broadcasts them for subscribers
  like the cache, UI, analytics, etc.
  
  Naming follows the pattern: {event}_to_pubsub_v{version}
  - Event: TemperatureMeasured -> temperature_measured
  - Target: PubSub -> pubsub
  """
  
  use Commanded.Event.Handler,
    application: GreenhouseTycoon.CommandedApp,
    name: "temperature_measured_to_pubsub_v1",
    subscribe_to: "$et-temperature_measured:v1"
  
  alias GreenhouseTycoon.MeasureTemperature.EventV1, as: TemperatureMeasuredEvent
  alias GreenhouseTycoon.ReadModels.GreenhouseReadModel
  
  require Logger
  
  def handle(%TemperatureMeasuredEvent{} = event, _metadata) do
    Logger.info("🌡️  Processing temperature measurement for greenhouse: #{event.greenhouse_id} - #{event.temperature}°C")
    
    read_model = %GreenhouseReadModel{
      greenhouse_id: event.greenhouse_id,
      current_temperature: event.temperature,
      updated_at: event.measured_at
    }
    
    # Broadcast the temperature measurement event
    case Phoenix.PubSub.broadcast(
           GreenhouseTycoon.PubSub,
           "greenhouse_projections",
           {:temperature_measured, read_model}
         ) do
      :ok ->
        Logger.info("✅ Temperature measurement event broadcasted for: #{event.greenhouse_id}")
        :ok
        
      {:error, reason} ->
        Logger.error("❌ Failed to broadcast temperature measurement for: #{event.greenhouse_id}, reason: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
