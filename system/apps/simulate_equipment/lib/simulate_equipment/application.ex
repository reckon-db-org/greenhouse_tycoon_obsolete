defmodule SimulateEquipment.Application do
  @moduledoc """
  Application for simulating equipment operation and maintenance events.

  This application:
  - Listens for equipment-related events from ControlEquipment
  - Maintains simulation state for each greenhouse's equipment
  - Emits realistic equipment usage and maintenance events
  - Responds to operational changes
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # PubSub for cross-app communication
      {Phoenix.PubSub, name: SimulateEquipment.PubSub},

      # Registry to track greenhouse equipment simulations
      {Registry, keys: :unique, name: SimulateEquipment.Registry},

      # Dynamic supervisor that spawns GreenhouseEquipmentSupervisor per greenhouse
      {DynamicSupervisor, name: SimulateEquipment.SimulationSupervisor, strategy: :one_for_one},

      # Global event listener that coordinates greenhouse lifecycle
      SimulateEquipment.GlobalEventListener
    ]

    opts = [strategy: :one_for_one, name: SimulateEquipment.Supervisor]

    Logger.info("Starting SimulateEquipment Application")
    result = Supervisor.start_link(children, opts)

    case result do
      {:ok, _pid} -> Logger.info("SimulateEquipment Application started successfully")
      error -> Logger.error("Failed to start SimulateEquipment Application: #{inspect(error)}")
    end

    result
  end
end

