defmodule ManageGreenhouse.GreenhouseProcess do
  @moduledoc """
  Represents an individual greenhouse instance.

  Each greenhouse process manages independent simulation control,
  configuration management, and interaction with other contexts.
  """

  use GenServer
  require Logger

  alias ManageGreenhouse.{Events, Commands}

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: via_tuple(args.greenhouse_id))
  end

  def init(args) do
    Logger.info("Starting greenhouse process for ID: #{args.greenhouse_id}")

    {:ok, %{
      greenhouse_id: args.greenhouse_id,
      name: args.name,
      location: args.location,
      active: false,
      simulator: nil,
      config: args.config || %{}
    }}
  end

  def handle_call(:activate, _from, state) do
    # Logic to handle activation
    Logger.info("Activating greenhouse: #{state.greenhouse_id}")
    {:reply, :ok, %{state | active: true}}
  end

  def handle_call(:deactivate, _from, state) do
    # Logic to handle deactivation
    Logger.info("Deactivating greenhouse: #{state.greenhouse_id}")
    {:reply, :ok, %{state | active: false}}
  end

  def handle_call({:start_simulation, config}, _from, state) do
    # Logic to start simulation
    Logger.info("Starting simulation for greenhouse: #{state.greenhouse_id}")
    {:reply, :ok, %{state | simulator: start_simulator(state.greenhouse_id, config)}}
  end

  def handle_call(:stop_simulation, _from, state) do
    # Logic to stop simulation
    Logger.info("Stopping simulation for greenhouse: #{state.greenhouse_id}")
    stop_simulator(state.simulator)
    {:reply, :ok, %{state | simulator: nil}}
  end

  # Helper functions
  defp start_simulator(greenhouse_id, config), do: {:simulator, greenhouse_id, config}
  defp stop_simulator(simulator), do: Logger.info("Stopping simulator for #{inspect(simulator)}")

  defp via_tuple(greenhouse_id), do: {:via, Registry, {Registry.Greenhouses, greenhouse_id}}
end

