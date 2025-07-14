defmodule ManageCrops.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      ManageCrops.Repo,
      {Ecto.Migrator,
        repos: Application.fetch_env!(:manage_crops, :ecto_repos),
        skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:manage_crops, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ManageCrops.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ManageCrops.Finch},
      # Start the APIs Countries service for country data
      {Apis.Countries, [true]},
      # Start the cache service for read models
      ManageCrops.CacheService,
      # Start the infrastructure supervisor for reliability components
      ManageCrops.Infrastructure.Supervisor,
      # Start the Commanded application (without projections)
      ManageCrops.CommandedApp,
      # Start the event-type-based projection manager
      ManageCrops.Projections.EventTypeProjectionManager,
      # Start the cache population service for startup cache rebuilding
      ManageCrops.CachePopulationService
      # Start a worker by calling: ManageCrops.Worker.start_link(arg)
      # {ManageCrops.Worker, arg}
    ]

    opts = [strategy: :one_for_one, name: ManageCrops.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
