defmodule Simulator.Application do
  @moduledoc """
  OTP Application for the Greenhouse Simulator.
  
  This module sets up the supervision tree for the simulator, including:
  - Event subscription management
  - Simulation servers for active greenhouses
  - Periodic simulation schedulers
  - Event publishing infrastructure
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # Core simulation infrastructure
      {Phoenix.PubSub, name: Simulator.PubSub},
      {Registry, keys: :unique, name: Simulator.Registry},
      
      # Dynamic supervisor for simulation servers
      {DynamicSupervisor, name: Simulator.SimulationSupervisor, strategy: :one_for_one},
      
      # Event subscription manager
      Simulator.EventSubscriptionManager,
      
      # Simulation scheduler for periodic updates
      Simulator.SimulationScheduler,

      # Weather API integration for environmental data
      Simulator.WeatherAPIIntegration,
      
      # Autonomous simulation engine
      Simulator.AutonomousEngine,
      
      # Metrics and monitoring
      Simulator.Metrics,
      
      # Main supervisor for simulation instances
      Simulator.Supervisor
    ]

    opts = [strategy: :one_for_one, name: Simulator.ApplicationSupervisor]
    
    Logger.info("Starting Simulator Application")
    result = Supervisor.start_link(children, opts)
    
    case result do
      {:ok, _pid} -> Logger.info("Simulator Application started successfully")
      error -> Logger.error("Failed to start Simulator Application: #{inspect(error)}")
    end
    
    result
  end
end
