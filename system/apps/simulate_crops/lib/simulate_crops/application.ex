defmodule SimulateCrops.Application do
  @moduledoc """
  Application for simulating crop growth and lifecycle events.
  
  This application:
  - Listens for crop-related events from ManageCrops
  - Maintains simulation state for each greenhouse's crops  
  - Emits realistic crop simulation events
  - Responds to environmental changes
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # PubSub for cross-app communication
      {Phoenix.PubSub, name: SimulateCrops.PubSub},
      
      # Registry to track greenhouse crop simulations
      {Registry, keys: :unique, name: SimulateCrops.Registry},
      
      # Dynamic supervisor that spawns GreenhouseCropSupervisor per greenhouse
      {DynamicSupervisor, name: SimulateCrops.SimulationSupervisor, strategy: :one_for_one},
      
      # Global event listener that coordinates greenhouse lifecycle
      SimulateCrops.GlobalEventListener
    ]

    opts = [strategy: :one_for_one, name: SimulateCrops.Supervisor]
    
    Logger.info("Starting SimulateCrops Application")
    result = Supervisor.start_link(children, opts)
    
    case result do
      {:ok, _pid} -> Logger.info("SimulateCrops Application started successfully")
      error -> Logger.error("Failed to start SimulateCrops Application: #{inspect(error)}")
    end
    
    result
  end
end
