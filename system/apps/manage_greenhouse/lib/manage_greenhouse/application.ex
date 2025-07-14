defmodule ManageGreenhouse.Application do
  @moduledoc """
  Application for managing greenhouse lifecycle operations.

  This module sets up the supervision tree for the greenhouse management system,
  including individual greenhouse processes and their simulators.
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      {DNSCluster, query: Application.get_env(:manage_greenhouse, :dns_cluster_query) || :ignore},
      # Start the APIs Countries service for country data
      {Apis.Countries, [true]},
      # Start the cache service for read models
      ManageGreenhouse.CacheService,
      # Start the infrastructure supervisor for reliability components
      ManageGreenhouse.Infrastructure.Supervisor,
      # Registry for greenhouse processes
      {Registry, keys: :unique, name: Registry.Greenhouses},
      # Dynamic supervisor for individual greenhouse processes
      {DynamicSupervisor, name: ManageGreenhouse.GreenhouseSupervisor, strategy: :one_for_one},
      # Greenhouse manager - coordinates greenhouse lifecycle
      ManageGreenhouse.GreenhouseManager
      # TODO: Add back once modules are created:
      # ManageGreenhouse.CommandedApp,
      # ManageGreenhouse.Projections.EventTypeProjectionManager,
      # ManageGreenhouse.CachePopulationService,
    ]

    opts = [strategy: :one_for_one, name: ManageGreenhouse.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
