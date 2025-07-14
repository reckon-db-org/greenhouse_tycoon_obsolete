defmodule Simulator.WeatherAPIIntegration do
  use GenServer

  @moduledoc """
  Integrates with the WeatherService to fetch and apply real-time
  environmental data to the simulation.
  """

  require Logger
  alias RegulateGreenhouse.WeatherService

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    Logger.info("WeatherAPIIntegration: Started")
    schedule_fetch()
    {:ok, %{}}  # Initial state can be expanded as needed
  end

  def handle_info(:fetch_weather, state) do
    # Simulate fetching weather data (latitude and longitude can be dynamic)
    latitude = 35.6895
    longitude = 139.6917
    Logger.info("WeatherAPIIntegration: Fetching weather data")

    case WeatherService.get_current_weather(latitude, longitude, nil) do
      {:ok, data} ->
        Logger.info("WeatherAPIIntegration: Weather data fetched successfully")
        # Process and adapt the weather data to simulation needs
        apply_weather_to_simulation(data)
        schedule_fetch()  # Reschedule the next fetch
        {:noreply, state}
      {:error, reason} ->
        Logger.error("WeatherAPIIntegration: Failed to fetch weather data: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  defp schedule_fetch do
    Process.send_after(self(), :fetch_weather, :timer.hours(1))
  end

  defp apply_weather_to_simulation(weather_data) do
    # Function to process weather data and adapt it to simulation
    # This could involve triggering events or adjusting internal states
    # For example, adjusting greenhouse temperature, humidity, etc.
    Logger.debug("WeatherAPIIntegration: Applying weather data to simulation #{inspect(weather_data)}")
  end
end

