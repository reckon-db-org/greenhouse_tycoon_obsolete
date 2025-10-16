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
      # Start the BCApis Countries service for country data
      {BCApis.Countries, [true]},
      # Start ExESDB system for this app
      {ExESDB.System, enhanced_config},
      # Start the Ecto repository
      GreenhouseTycoon.Repo,
      # Start the Commanded application
      GreenhouseTycoon.CommandedApp,
      # Start the vertical slice projections
      GreenhouseTycoon.InitializeGreenhouse.InitializedToGreenhouseEctoV1,
      GreenhouseTycoon.MeasureTemperature.TemperatureMeasuredToGreenhouseEctoV1,
      GreenhouseTycoon.MeasureHumidity.HumidityMeasuredToGreenhouseEctoV1,
      GreenhouseTycoon.MeasureLight.LightMeasuredToGreenhouseEctoV1,
      GreenhouseTycoon.SetTargetTemperature.TargetTemperatureSetToGreenhouseEctoV1,
      GreenhouseTycoon.SetTargetHumidity.TargetHumiditySetToGreenhouseEctoV1,
      GreenhouseTycoon.SetTargetLight.TargetLightSetToGreenhouseEctoV1,
      # Start the infrastructure supervisor for reliability components
      GreenhouseTycoon.Infrastructure.Supervisor,
      # Start the weather measurement service for automatic weather-based measurements
      GreenhouseTycoon.WeatherMeasurementService
    ]

    opts = [strategy: :one_for_one, name: GreenhouseTycoon.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
