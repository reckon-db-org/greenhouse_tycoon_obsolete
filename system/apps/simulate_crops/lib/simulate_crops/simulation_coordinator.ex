defmodule SimulateCrops.SimulationCoordinator do
  @moduledoc """
  Coordinates crop simulations across greenhouses.
  
  Manages the lifecycle of individual crop simulation processes
  and handles cross-greenhouse simulation coordination.
  """
  
  use GenServer
  require Logger
  
  alias SimulateCrops.GreenhouseCropSimulator
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(_opts) do
    Logger.info("SimulateCrops.SimulationCoordinator: Starting simulation coordinator")
    
    {:ok, %{
      greenhouse_simulators: %{},
      crop_simulations: %{}
    }}
  end
  
  # Public API
  
  def initialize_greenhouse_simulation(greenhouse_id, config) do
    GenServer.call(__MODULE__, {:initialize_greenhouse, greenhouse_id, config})
  end
  
  def start_crop_simulation(greenhouse_id, crop_id, crop_config) do
    GenServer.call(__MODULE__, {:start_crop_simulation, greenhouse_id, crop_id, crop_config})
  end
  
  def stop_crop_simulation(greenhouse_id, crop_id) do
    GenServer.call(__MODULE__, {:stop_crop_simulation, greenhouse_id, crop_id})
  end
  
  def stop_greenhouse_simulation(greenhouse_id) do
    GenServer.call(__MODULE__, {:stop_greenhouse_simulation, greenhouse_id})
  end
  
  def update_environmental_conditions(greenhouse_id, conditions) do
    GenServer.cast(__MODULE__, {:update_environment, greenhouse_id, conditions})
  end
  
  def get_simulation_status(greenhouse_id) do
    GenServer.call(__MODULE__, {:get_status, greenhouse_id})
  end
  
  # GenServer callbacks
  
  def handle_call({:initialize_greenhouse, greenhouse_id, config}, _from, state) do
    Logger.info("SimulationCoordinator: Initializing greenhouse simulation for #{greenhouse_id}")
    
    # Start a greenhouse crop simulator
    simulator_spec = {
      GreenhouseCropSimulator,
      [greenhouse_id: greenhouse_id, config: config]
    }
    
    case DynamicSupervisor.start_child(SimulateCrops.SimulationSupervisor, simulator_spec) do
      {:ok, pid} ->
        new_state = %{
          state | 
          greenhouse_simulators: Map.put(state.greenhouse_simulators, greenhouse_id, pid)
        }
        {:reply, {:ok, pid}, new_state}
        
      {:error, reason} ->
        Logger.error("SimulationCoordinator: Failed to start greenhouse simulator: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end
  
  def handle_call({:start_crop_simulation, greenhouse_id, crop_id, crop_config}, _from, state) do
    Logger.info("SimulationCoordinator: Starting crop simulation for #{crop_id} in #{greenhouse_id}")
    
    case Map.get(state.greenhouse_simulators, greenhouse_id) do
      nil ->
        Logger.warning("SimulationCoordinator: No greenhouse simulator found for #{greenhouse_id}")
        {:reply, {:error, :greenhouse_not_found}, state}
        
      simulator_pid ->
        # Delegate to the greenhouse simulator
        result = GreenhouseCropSimulator.start_crop_simulation(simulator_pid, crop_id, crop_config)
        
        # Track the crop simulation
        crop_key = {greenhouse_id, crop_id}
        new_state = %{
          state | 
          crop_simulations: Map.put(state.crop_simulations, crop_key, %{
            started_at: DateTime.utc_now(),
            config: crop_config,
            status: :active
          })
        }
        
        {:reply, result, new_state}
    end
  end
  
  def handle_call({:stop_crop_simulation, greenhouse_id, crop_id}, _from, state) do
    Logger.info("SimulationCoordinator: Stopping crop simulation for #{crop_id} in #{greenhouse_id}")
    
    case Map.get(state.greenhouse_simulators, greenhouse_id) do
      nil ->
        {:reply, {:error, :greenhouse_not_found}, state}
        
      simulator_pid ->
        result = GreenhouseCropSimulator.stop_crop_simulation(simulator_pid, crop_id)
        
        # Remove crop simulation tracking
        crop_key = {greenhouse_id, crop_id}
        new_state = %{
          state | 
          crop_simulations: Map.delete(state.crop_simulations, crop_key)
        }
        
        {:reply, result, new_state}
    end
  end
  
  def handle_call({:stop_greenhouse_simulation, greenhouse_id}, _from, state) do
    Logger.info("SimulationCoordinator: Stopping greenhouse simulation for #{greenhouse_id}")
    
    case Map.get(state.greenhouse_simulators, greenhouse_id) do
      nil ->
        {:reply, {:error, :greenhouse_not_found}, state}
        
      simulator_pid ->
        # Stop the greenhouse simulator
        DynamicSupervisor.terminate_child(SimulateCrops.SimulationSupervisor, simulator_pid)
        
        # Clean up tracking
        new_state = %{
          state | 
          greenhouse_simulators: Map.delete(state.greenhouse_simulators, greenhouse_id),
          crop_simulations: Map.reject(state.crop_simulations, fn {{gh_id, _crop_id}, _config} ->
            gh_id == greenhouse_id
          end)
        }
        
        {:reply, :ok, new_state}
    end
  end
  
  def handle_call({:get_status, greenhouse_id}, _from, state) do
    status = %{
      greenhouse_active: Map.has_key?(state.greenhouse_simulators, greenhouse_id),
      active_crops: state.crop_simulations
        |> Enum.filter(fn {{gh_id, _crop_id}, _config} -> gh_id == greenhouse_id end)
        |> Enum.map(fn {{_gh_id, crop_id}, config} -> {crop_id, config} end)
    }
    
    {:reply, status, state}
  end
  
  def handle_cast({:update_environment, greenhouse_id, conditions}, state) do
    case Map.get(state.greenhouse_simulators, greenhouse_id) do
      nil ->
        Logger.debug("SimulationCoordinator: No greenhouse simulator to update for #{greenhouse_id}")
        
      simulator_pid ->
        GreenhouseCropSimulator.update_environmental_conditions(simulator_pid, conditions)
    end
    
    {:noreply, state}
  end
end
