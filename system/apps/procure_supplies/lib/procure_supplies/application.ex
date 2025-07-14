defmodule ProcureSupplies.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      ProcureSupplies.Repo,
      {Ecto.Migrator,
        repos: Application.fetch_env!(:procure_supplies, :ecto_repos),
        skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:procure_supplies, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ProcureSupplies.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ProcureSupplies.Finch},
      # Start the APIs Countries service for country data
      {Apis.Countries, [true]},
      # Start the cache service for read models
      ProcureSupplies.CacheService,
      # Start the infrastructure supervisor for reliability components
      ProcureSupplies.Infrastructure.Supervisor,
      # Start the Commanded application (without projections)
      ProcureSupplies.CommandedApp,
      # Start the event-type-based projection manager
      ProcureSupplies.Projections.EventTypeProjectionManager,
      # Start the cache population service for startup cache rebuilding
      ProcureSupplies.CachePopulationService
      # Start a worker by calling: ProcureSupplies.Worker.start_link(arg)
      # {ProcureSupplies.Worker, arg}
    ]

    opts = [strategy: :one_for_one, name: ProcureSupplies.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
