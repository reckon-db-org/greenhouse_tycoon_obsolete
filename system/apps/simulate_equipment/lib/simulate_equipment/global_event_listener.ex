defmodule SimulateEquipment.GlobalEventListener do
  @moduledoc """
  Global event listener that coordinates greenhouse lifecycle for equipment simulations.

  This process listens for greenhouse lifecycle events and starts/stops
  GreenhouseEquipmentSupervisor processes for each greenhouse.
  """

  use GenServer
  require Logger

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    # Subscribe to greenhouse lifecycle events
    Phoenix.PubSub.subscribe(SimulateEquipment.PubSub, "greenhouse:lifecycle")

    Logger.info("GlobalEventListener started for greenhouse lifecycle events")

    {:ok, %{greenhouses: %{}}}
  end

  @impl true
  def handle_info({:greenhouse_initialized, greenhouse_id}, state) do
    Logger.info("Initializing equipment simulation for greenhouse #{greenhouse_id}")

    start_greenhouse_simulation(greenhouse_id)

    updated_state = put_in(state, [:greenhouses, greenhouse_id], :initialized)
    {:noreply, updated_state}
  end

  @impl true
  def handle_info({:greenhouse_activated, greenhouse_id}, state) do
    Logger.info("Activating equipment simulation for greenhouse #{greenhouse_id}")

    # Start the simulation if not already started
    start_greenhouse_simulation(greenhouse_id)

    updated_state = put_in(state, [:greenhouses, greenhouse_id], :active)
    {:noreply, updated_state}
  end

  @impl true
  def handle_info({:greenhouse_deactivated, greenhouse_id}, state) do
    Logger.info("Deactivating equipment simulation for greenhouse #{greenhouse_id}")

    stop_greenhouse_simulation(greenhouse_id)

    updated_state = put_in(state, [:greenhouses, greenhouse_id], :inactive)
    {:noreply, updated_state}
  end

  @impl true
  def handle_info({:greenhouse_retired, greenhouse_id}, state) do
    Logger.info("Retiring equipment simulation for greenhouse #{greenhouse_id}")

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
      SimulateEquipment.SimulationSupervisor,
      {SimulateEquipment.GreenhouseEquipmentSupervisor, greenhouse_id}
    ) do
      {:ok, _pid} ->
        Logger.info("Started equipment simulation supervisor for greenhouse #{greenhouse_id}")
        :ok

      {:error, {:already_started, _pid}} ->
        Logger.debug("Equipment simulation supervisor already running for greenhouse #{greenhouse_id}")
        :ok

      {:error, reason} ->
        Logger.error("Failed to start equipment simulation supervisor for greenhouse #{greenhouse_id}: #{inspect(reason)}")
        :error
    end
  end

  defp stop_greenhouse_simulation(greenhouse_id) do
    case Registry.lookup(SimulateEquipment.Registry, "#{greenhouse_id}_equipment_supervisor") do
      [{pid, _}] ->
        case DynamicSupervisor.terminate_child(SimulateEquipment.SimulationSupervisor, pid) do
          :ok ->
            Logger.info("Stopped equipment simulation supervisor for greenhouse #{greenhouse_id}")
            :ok

          {:error, reason} ->
            Logger.error("Failed to stop equipment simulation supervisor for greenhouse #{greenhouse_id}: #{inspect(reason)}")
            :error
        end

      [] ->
        Logger.debug("No equipment simulation supervisor found for greenhouse #{greenhouse_id}")
        :ok
    end
  end
end
