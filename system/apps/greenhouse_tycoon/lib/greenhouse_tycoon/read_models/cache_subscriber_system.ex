defmodule GreenhouseTycoon.ReadModels.CacheSubscriberSystem do
  @moduledoc """
  Supervisor for all cache subscriber processes.
  
  This supervisor manages all the cache subscribers that listen to projection events
  and update the greenhouse read model cache. It provides a clean way to start, stop,
  and monitor all cache-related subscribers as a cohesive system.
  
  Each cache subscriber is responsible for one specific event type and follows
  the vertical slicing architecture by living in its respective slice directory.
  """
  
  use Supervisor
  
  require Logger
  
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(_opts) do
    Logger.info("🗄️  Starting Cache Subscriber System")
    
    children = [
      # Greenhouse initialization cache subscriber
      {GreenhouseTycoon.InitializeGreenhouse.InitializedToGreenhouseCacheV1, []},
      
      # Temperature measurement cache subscriber
      {GreenhouseTycoon.MeasureTemperature.TemperatureMeasuredToGreenhouseCacheV1, []},
      
      # Target temperature set cache subscriber
      {GreenhouseTycoon.SetTargetTemperature.TargetTemperatureSetToGreenhouseCacheV1, []},
      
      # Humidity measurement cache subscriber
      {GreenhouseTycoon.MeasureHumidity.HumidityMeasuredToGreenhouseCacheV1, []},
      
      # Target humidity set cache subscriber
      {GreenhouseTycoon.SetTargetHumidity.TargetHumiditySetToGreenhouseCacheV1, []},
      
      # Light measurement cache subscriber
      {GreenhouseTycoon.MeasureLight.LightMeasuredToGreenhouseCacheV1, []},
      
      # Target light set cache subscriber
      {GreenhouseTycoon.SetTargetLight.TargetLightSetToGreenhouseCacheV1, []}
    ]
    
    # Use :one_for_one strategy - if one subscriber fails, only restart that one
    # This ensures that other subscribers continue working if one has issues
    opts = [
      strategy: :one_for_one,
      name: __MODULE__
    ]
    
    Logger.info("✅ Cache Subscriber System started with #{length(children)} subscribers")
    
    Supervisor.init(children, opts)
  end
  
  @doc """
  Get the status of all cache subscribers.
  
  Returns a list of {module, pid, status} tuples for monitoring purposes.
  """
  def subscriber_status do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(fn {module, pid, _type, _modules} ->
      status = if Process.alive?(pid), do: :running, else: :stopped
      {module, pid, status}
    end)
  end
  
  @doc """
  Restart a specific cache subscriber.
  
  Useful for debugging or when a specific subscriber needs to be restarted.
  """
  def restart_subscriber(module) do
    case Supervisor.terminate_child(__MODULE__, module) do
      :ok ->
        case Supervisor.restart_child(__MODULE__, module) do
          {:ok, _pid} ->
            Logger.info("✅ Successfully restarted cache subscriber: #{inspect(module)}")
            :ok
          {:error, reason} ->
            Logger.error("❌ Failed to restart cache subscriber #{inspect(module)}: #{inspect(reason)}")
            {:error, reason}
        end
      {:error, reason} ->
        Logger.error("❌ Failed to terminate cache subscriber #{inspect(module)}: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
