defmodule GreenhouseTycoon.InitializeGreenhouse.InitializedToPubSubV1 do
  @moduledoc """
  Projection that handles GreenhouseInitialized events and broadcasts them to PubSub.
  
  This projection processes greenhouse initialization events and broadcasts them for subscribers
  to consume (cache, UI, analytics, etc.).
  Following the vertical slicing architecture, this projection lives in the same slice
  as the event it processes.
  
  Naming follows the pattern: {event}_to_pubsub_v{version}
  - Event: GreenhouseInitialized -> initialized
  - Target: PubSub -> pubsub
  """
  
  use Commanded.Event.Handler,
    application: GreenhouseTycoon.CommandedApp,
    name: "greenhouse_initialized_to_pubsub_v1",
    subscribe_to: "$et-greenhouse_initialized:v1"
  
  alias GreenhouseTycoon.InitializeGreenhouse.EventV1, as: GreenhouseInitializedEvent
  alias GreenhouseTycoon.ReadModels.GreenhouseReadModel
  
  require Logger
  
  def handle(%GreenhouseInitializedEvent{} = event, _metadata) do
    Logger.info("🏗️  Processing greenhouse initialization for: #{event.greenhouse_id}")
    
    read_model = create_read_model_from_event(event)
    
    # Broadcast the greenhouse creation event for subscribers
    case Phoenix.PubSub.broadcast(
           GreenhouseTycoon.PubSub,
           "greenhouse_projections",
           {:greenhouse_created, read_model}
         ) do
      :ok ->
        Logger.info("✅ Greenhouse creation event broadcasted for: #{event.greenhouse_id}")
        :ok
        
      {:error, reason} ->
        Logger.error("❌ Failed to broadcast greenhouse creation for: #{event.greenhouse_id}, reason: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  defp create_read_model_from_event(%GreenhouseInitializedEvent{} = event) do
    read_model = %GreenhouseReadModel{
      greenhouse_id: event.greenhouse_id,
      name: event.name,
      location: event.location,
      city: event.city,
      country: event.country,
      current_temperature: nil,
      current_humidity: nil,
      current_light: nil,
      target_temperature: event.target_temperature,
      target_humidity: event.target_humidity,
      target_light: event.target_light,
      status: :inactive,
      event_count: 1,
      created_at: event.initialized_at,
      updated_at: event.initialized_at
    }
    
    # Calculate initial status based on targets
    %{read_model | status: GreenhouseReadModel.calculate_status(read_model)}
  end
  
end
