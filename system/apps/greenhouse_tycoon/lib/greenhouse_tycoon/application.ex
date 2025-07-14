defmodule GreenhouseTycoon.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      GreenhouseTycoon.Repo,
      {Ecto.Migrator,
        repos: Application.fetch_env!(:greenhouse_tycoon, :ecto_repos),
        skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:greenhouse_tycoon, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GreenhouseTycoon.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: GreenhouseTycoon.Finch},
      # Start the APIs Countries service for country data
      {Apis.Countries, [true]},
      # Start the cache service for read models
      GreenhouseTycoon.CacheService,
      # Start the infrastructure supervisor for reliability components
      GreenhouseTycoon.Infrastructure.Supervisor,
      # Start the Commanded application (without projections)
      GreenhouseTycoon.CommandedApp,
      # Start the event-type-based projection manager
      GreenhouseTycoon.Projections.EventTypeProjectionManager,
      # Start the cache population service for startup cache rebuilding
      GreenhouseTycoon.CachePopulationService,
      # Start the weather measurement service for automatic weather-based measurements
      GreenhouseTycoon.WeatherMeasurementService
      # Start a worker by calling: GreenhouseTycoon.Worker.start_link(arg)
      # {GreenhouseTycoon.Worker, arg}
    ]

    opts = [strategy: :one_for_one, name: GreenhouseTycoon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
