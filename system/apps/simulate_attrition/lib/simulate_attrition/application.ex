defmodule SimulateAttrition.Application do
  @moduledoc """
  Application for simulating supply attrition and consumption in greenhouses.
  
  This application:
  - Listens for supply-related events from ProcureSupplies
  - Maintains simulation state for each greenhouse's supply levels
  - Emits realistic supply attrition and consumption events
  - Responds to equipment usage and environmental changes
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # PubSub for cross-app communication
      {Phoenix.PubSub, name: SimulateAttrition.PubSub},
      
      # Registry to track greenhouse supply simulations
      {Registry, keys: :unique, name: SimulateAttrition.Registry},
      
      # Dynamic supervisor that spawns GreenhouseSupplySupervisor per greenhouse
      {DynamicSupervisor, name: SimulateAttrition.SimulationSupervisor, strategy: :one_for_one},
      
      # Global event listener that coordinates greenhouse lifecycle
      SimulateAttrition.GlobalEventListener
    ]

    opts = [strategy: :one_for_one, name: SimulateAttrition.Supervisor]
    
    Logger.info("Starting SimulateAttrition Application")
    result = Supervisor.start_link(children, opts)
    
    case result do
      {:ok, _pid} -> Logger.info("SimulateAttrition Application started successfully")
      error -> Logger.error("Failed to start SimulateAttrition Application: #{inspect(error)}")
    end
    
    result
  end
end
