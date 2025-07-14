defmodule MaintainEquipment.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      MaintainEquipment.Repo,
      {Ecto.Migrator,
        repos: Application.fetch_env!(:maintain_equipment, :ecto_repos),
        skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:maintain_equipment, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MaintainEquipment.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: MaintainEquipment.Finch},
      # Start the APIs Countries service for country data
      {Apis.Countries, [true]},
      # Start the cache service for read models
      MaintainEquipment.CacheService,
      # Start the infrastructure supervisor for reliability components
      MaintainEquipment.Infrastructure.Supervisor,
      # Start the Commanded application (without projections)
      MaintainEquipment.CommandedApp,
      # Start the event-type-based projection manager
      MaintainEquipment.Projections.EventTypeProjectionManager,
      # Start the cache population service for startup cache rebuilding
      MaintainEquipment.CachePopulationService
      # Start a worker by calling: MaintainEquipment.Worker.start_link(arg)
      # {MaintainEquipment.Worker, arg}
    ]

    opts = [strategy: :one_for_one, name: MaintainEquipment.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end

