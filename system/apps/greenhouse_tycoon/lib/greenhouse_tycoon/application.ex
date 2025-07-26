defmodule GreenhouseTycoon.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    enhanced_config =
      Application.get_env(:greenhouse_tycoon, :ex_esdb, [])
      |> Keyword.put(:otp_app, :greenhouse_tycoon)

    children = [
      {DNSCluster, query: Application.get_env(:greenhouse_tycoon, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GreenhouseTycoon.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: GreenhouseTycoon.Finch},
      # Start the APIs Countries service for country data
      {Apis.Countries, [true]},
      # Start ExESDB system for this app
      {ExESDB.System, enhanced_config},
      # Start the cache service for read models
      GreenhouseTycoon.CacheService,
      # Start the cache subscriber system to manage all cache subscribers
      GreenhouseTycoon.ReadModels.CacheSubscriberSystem,
      # Start the infrastructure supervisor for reliability components
      GreenhouseTycoon.Infrastructure.Supervisor,
      # Start the Commanded application (without projections)
      GreenhouseTycoon.CommandedApp,
      # Cache population service enabled to rebuild cache from events
      GreenhouseTycoon.CachePopulationService,
      # Start the weather measurement service for automatic weather-based measurements
      GreenhouseTycoon.WeatherMeasurementService
      # Start a worker by calling: GreenhouseTycoon.Worker.start_link(arg)
      # {GreenhouseTycoon.Worker, arg}
    ]

    opts = [strategy: :one_for_one, name: GreenhouseTycoon.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
