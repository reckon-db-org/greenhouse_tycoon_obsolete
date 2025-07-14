defmodule SimulateCrops.GlobalEventListener do
  @moduledoc """
  Global event listener that coordinates greenhouse lifecycle for crop simulations.

  This process listens for greenhouse lifecycle events and starts/stops
  GreenhouseCropSupervisor processes for each greenhouse.
  """

  use GenServer
  require Logger

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    # Subscribe to greenhouse lifecycle events
    Phoenix.PubSub.subscribe(SimulateCrops.PubSub, "greenhouse:lifecycle")
    
    Logger.info("GlobalEventListener started for greenhouse lifecycle events")

    {:ok, %{greenhouses: %{}}}
  end

  @impl true
  def handle_info({:greenhouse_initialized, greenhouse_id}, state) do
    Logger.info("Initializing crop simulation for greenhouse #{greenhouse_id}")
    
    start_greenhouse_simulation(greenhouse_id)
    
    updated_state = put_in(state, [:greenhouses, greenhouse_id], :initialized)
    {:noreply, updated_state}
  end

  @impl true
  def handle_info({:greenhouse_activated, greenhouse_id}, state) do
    Logger.info("Activating crop simulation for greenhouse #{greenhouse_id}")
    
    # Start the simulation if not already started
    start_greenhouse_simulation(greenhouse_id)
    
    updated_state = put_in(state, [:greenhouses, greenhouse_id], :active)
    {:noreply, updated_state}
  end

  @impl true
  def handle_info({:greenhouse_deactivated, greenhouse_id}, state) do
    Logger.info("Deactivating crop simulation for greenhouse #{greenhouse_id}")
    
    stop_greenhouse_simulation(greenhouse_id)
    
    updated_state = put_in(state, [:greenhouses, greenhouse_id], :inactive)
    {:noreply, updated_state}
  end

  @impl true
  def handle_info({:greenhouse_retired, greenhouse_id}, state) do
    Logger.info("Retiring crop simulation for greenhouse #{greenhouse_id}")
    
    stop_greenhouse_simulation(greenhouse_id)
    
    {_, updated_state} = pop_in(state, [:greenhouses, greenhouse_id])
    {:noreply, updated_state}
  end

  @impl true
  def handle_info(event, state) do
    Logger.debug("Ignoring event: #{inspect(event)}")
    {:noreply, state}
  end

  defp start_greenhouse_simulation(greenhouse_id) do
    case DynamicSupervisor.start_child(
      SimulateCrops.SimulationSupervisor,
      {SimulateCrops.GreenhouseCropSupervisor, greenhouse_id}
    ) do
      {:ok, _pid} ->
        Logger.info("Started crop simulation supervisor for greenhouse #{greenhouse_id}")
        :ok
      
      {:error, {:already_started, _pid}} ->
        Logger.debug("Crop simulation supervisor already running for greenhouse #{greenhouse_id}")
        :ok
      
      {:error, reason} ->
        Logger.error("Failed to start crop simulation supervisor for greenhouse #{greenhouse_id}: #{inspect(reason)}")
        :error
    end
  end

  defp stop_greenhouse_simulation(greenhouse_id) do
    case Registry.lookup(SimulateCrops.Registry, "#{greenhouse_id}_crop_supervisor") do
      [{pid, _}] ->
        case DynamicSupervisor.terminate_child(SimulateCrops.SimulationSupervisor, pid) do
          :ok ->
            Logger.info("Stopped crop simulation supervisor for greenhouse #{greenhouse_id}")
            :ok
          
          {:error, reason} ->
            Logger.error("Failed to stop crop simulation supervisor for greenhouse #{greenhouse_id}: #{inspect(reason)}")
            :error
        end
      
      [] ->
        Logger.debug("No crop simulation supervisor found for greenhouse #{greenhouse_id}")
        :ok
    end
  end
end
