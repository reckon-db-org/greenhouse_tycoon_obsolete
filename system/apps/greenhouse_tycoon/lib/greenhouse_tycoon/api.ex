defmodule GreenhouseTycoon.API do
  @moduledoc """
  Public API for the GreenhouseTycoon Commanded application.

  This module provides functions to dispatch commands and query
  the greenhouse regulation domain.
  """

  alias GreenhouseTycoon.CommandedApp

  import Ecto.Query, warn: false

  alias GreenhouseTycoon.InitializeGreenhouse.CommandV1, as: InitializeGreenhouse
  alias GreenhouseTycoon.SetTargetTemperature.CommandV1, as: SetTargetTemperature
  alias GreenhouseTycoon.SetTargetHumidity.CommandV1, as: SetTargetHumidity
  alias GreenhouseTycoon.SetTargetLight.CommandV1, as: SetTargetLight
  alias GreenhouseTycoon.MeasureTemperature.CommandV1, as: MeasureTemperature
  alias GreenhouseTycoon.MeasureHumidity.CommandV1, as: MeasureHumidity
  alias GreenhouseTycoon.MeasureLight.CommandV1, as: MeasureLight

  @doc """
  Creates a new greenhouse.
  """
  @spec create_greenhouse(String.t(), String.t(), String.t(), String.t(), String.t(), float() | nil, float() | nil) ::
          :ok | {:error, term()}
  def create_greenhouse(
        greenhouse_id,
        name,
        location,
        city,
        country,
        target_temperature \\ nil,
        target_humidity \\ nil
      ) do
    require Logger

    command = %InitializeGreenhouse{
      greenhouse_id: greenhouse_id,
      name: name,
      location: location,
      city: city,
      country: country,
      target_temperature: target_temperature,
      target_humidity: target_humidity
    }

    case CommandedApp.dispatch_command(command) do
      :ok ->
        :ok

      error ->
        Logger.error(
          "API: Failed to dispatch InitializeGreenhouse for #{greenhouse_id}: #{inspect(error)}"
        )

        error
    end
  end

  @doc """
  Initializes a greenhouse with sensor readings.
  """
  @spec initialize_greenhouse(String.t(), float(), float(), float()) :: :ok | {:error, term()}
  def initialize_greenhouse(greenhouse_id, temperature, humidity, light) do
    require Logger

    Logger.info(
      "API: Initializing greenhouse #{greenhouse_id} - ONLY CREATING, measurements disabled for debugging"
    )

    # First create the greenhouse
    case create_greenhouse(greenhouse_id, greenhouse_id, "Unknown", "Unknown", "Unknown") do
      :ok ->
        Logger.info(
          "API: Greenhouse #{greenhouse_id} created successfully (measurements disabled)"
        )

        # Measurements temporarily disabled for debugging
        # :timer.sleep(500)
        # Logger.info("API: Starting measurements for #{greenhouse_id}")
        # with :ok <- measure_temperature(greenhouse_id, temperature),
        #      :ok <- measure_humidity(greenhouse_id, humidity),
        #      :ok <- measure_light(greenhouse_id, light) do
        #   Logger.info("API: Completed initialization for #{greenhouse_id}")
        #   :ok
        # end
        Logger.info("API: Completed initialization for #{greenhouse_id} (measurements disabled)")
        :ok

      error ->
        error
    end
  end

  @doc """
  Initializes a greenhouse with full details including name, location, city, and country.
  """
  @spec initialize_greenhouse(String.t(), String.t(), String.t(), String.t(), String.t()) :: :ok | {:error, term()}
  def initialize_greenhouse(greenhouse_id, name, location, city, country) do
    require Logger

    Logger.info("API: Initializing greenhouse #{greenhouse_id} with full details")

    case create_greenhouse(greenhouse_id, name, location, city, country) do
      :ok ->
        Logger.info("API: Greenhouse #{greenhouse_id} initialized successfully")
        :ok

      error ->
        error
    end
  end

  @doc """
  Resets/removes a greenhouse for testing purposes.
  Note: This is a simplified implementation that doesn't actually remove data from event store.
  """
  @spec reset_greenhouse(String.t()) :: :ok
  def reset_greenhouse(greenhouse_id) do
    require Logger
    Logger.info("API: Resetting greenhouse #{greenhouse_id} (database record only)")
    
    # In a production system, you might want to delete events or mark them as deleted
    # For now, we'll just delete the database record
    case GreenhouseTycoon.Repo.delete_all(
      from g in GreenhouseTycoon.Greenhouse, where: g.greenhouse_id == ^greenhouse_id
    ) do
      {0, _} -> 
        Logger.info("API: Reset greenhouse #{greenhouse_id} (was not in database)")
        :ok
      {count, _} when count > 0 ->
        Logger.info("API: Successfully reset greenhouse #{greenhouse_id}")
        :ok
    end
  end

  @doc """
  Sets the target temperature for a greenhouse.
  """
  @spec set_temperature(String.t(), float(), String.t() | nil) :: :ok | {:error, term()}
  def set_temperature(greenhouse_id, target_temperature, set_by \\ nil) do
    require Logger

    Logger.info(
      "API: Setting temperature for #{greenhouse_id} to #{target_temperature}°C (set_by: #{set_by})"
    )

    command = %SetTargetTemperature{
      greenhouse_id: greenhouse_id,
      target_temperature: target_temperature,
      set_by: set_by
    }

    case CommandedApp.dispatch_command(command) do
      :ok ->
        Logger.info("API: Successfully set temperature for #{greenhouse_id}")
        :ok

      error ->
        Logger.error("API: Failed to set temperature for #{greenhouse_id}: #{inspect(error)}")
        error
    end
  end

  @doc """
  Sets the desired temperature for a greenhouse.
  """
  @spec set_desired_temperature(String.t(), float()) :: :ok | {:error, term()}
  def set_desired_temperature(greenhouse_id, temperature) do
    set_temperature(greenhouse_id, temperature)
  end

  @doc """
  Sets the target humidity for a greenhouse.
  """
  @spec set_humidity(String.t(), float(), String.t() | nil) :: :ok | {:error, term()}
  def set_humidity(greenhouse_id, target_humidity, set_by \\ nil) do
    require Logger

    Logger.info(
      "API: Setting humidity for #{greenhouse_id} to #{target_humidity}% (set_by: #{set_by})"
    )

    command = %SetTargetHumidity{
      greenhouse_id: greenhouse_id,
      target_humidity: target_humidity,
      set_by: set_by
    }

    case CommandedApp.dispatch_command(command) do
      :ok ->
        Logger.info("API: Successfully set humidity for #{greenhouse_id}")
        :ok

      error ->
        Logger.error("API: Failed to set humidity for #{greenhouse_id}: #{inspect(error)}")
        error
    end
  end

  @doc """
  Sets the desired humidity for a greenhouse.
  """
  @spec set_desired_humidity(String.t(), float()) :: :ok | {:error, term()}
  def set_desired_humidity(greenhouse_id, humidity) do
    set_humidity(greenhouse_id, humidity)
  end

  @doc """
  Sets the desired light level for a greenhouse.
  """
  @spec set_desired_light(String.t(), float()) :: :ok | {:error, term()}
  def set_desired_light(greenhouse_id, light) do
    require Logger
    Logger.info("API: Setting light for #{greenhouse_id} to #{light} lumens")

    command = %SetTargetLight{
      greenhouse_id: greenhouse_id,
      target_light: light
    }

    case CommandedApp.dispatch_command(command) do
      :ok ->
        Logger.info("API: Successfully set light for #{greenhouse_id}")
        :ok

      error ->
        Logger.error("API: Failed to set light for #{greenhouse_id}: #{inspect(error)}")
        error
    end
  end

  @doc """
  Records a temperature measurement for a greenhouse.
  """
  @spec measure_temperature(String.t(), float()) :: :ok | {:error, term()}
  def measure_temperature(greenhouse_id, temperature) do
    require Logger
    Logger.info("API: Recording temperature measurement for #{greenhouse_id}: #{temperature}°C")

    command = %MeasureTemperature{
      greenhouse_id: greenhouse_id,
      temperature: temperature,
      measured_at: DateTime.utc_now(),
      measurement_type: :sensor
    }

    case CommandedApp.dispatch_command(command) do
      :ok ->
        Logger.info("API: Successfully recorded temperature measurement for #{greenhouse_id}")
        :ok

      error ->
        Logger.error(
          "API: Failed to record temperature measurement for #{greenhouse_id}: #{inspect(error)}"
        )

        error
    end
  end

  @doc """
  Records a humidity measurement for a greenhouse.
  """
  @spec measure_humidity(String.t(), float()) :: :ok | {:error, term()}
  def measure_humidity(greenhouse_id, humidity) do
    require Logger
    Logger.info("API: Recording humidity measurement for #{greenhouse_id}: #{humidity}%")

    command = %MeasureHumidity{
      greenhouse_id: greenhouse_id,
      humidity: humidity,
      measured_at: DateTime.utc_now()
    }

    case CommandedApp.dispatch_command(command) do
      :ok ->
        Logger.info("API: Successfully recorded humidity measurement for #{greenhouse_id}")
        :ok

      error ->
        Logger.error(
          "API: Failed to record humidity measurement for #{greenhouse_id}: #{inspect(error)}"
        )

        error
    end
  end

  @doc """
  Records a light measurement for a greenhouse.
  """
  @spec measure_light(String.t(), float()) :: :ok | {:error, term()}
  def measure_light(greenhouse_id, light) do
    require Logger
    Logger.info("API: Recording light measurement for #{greenhouse_id}: #{light} lumens")

    command = %MeasureLight{
      greenhouse_id: greenhouse_id,
      light: light,
      measured_at: DateTime.utc_now()
    }

    case CommandedApp.dispatch_command(command) do
      :ok ->
        Logger.info("API: Successfully recorded light measurement for #{greenhouse_id}")
        :ok

      error ->
        Logger.error(
          "API: Failed to record light measurement for #{greenhouse_id}: #{inspect(error)}"
        )

        error
    end
  end

  @doc """
  Lists all known greenhouse IDs.
  """
  @spec list_greenhouses() :: [String.t()]
  def list_greenhouses do
    GreenhouseTycoon.Repo.all(GreenhouseTycoon.Greenhouse)
    |> Enum.map(& &1.greenhouse_id)
  end

  @doc """
  Get all countries for country selection dropdown
  """
  def get_countries do
    try do
      countries = BCApis.Countries.all_countries()
      {:ok, countries |> Enum.sort()}
    rescue
      _ -> {:error, "Countries service unavailable"}
    end
  end

  @doc """
  Get country by country code
  """
  def get_country_by_code(country_code) do
    try do
      BCApis.Countries.get_country_by_country_code(country_code)
    rescue
      _ -> {:error, "Countries service unavailable"}
    end
  end

  @doc """
  Get country information by name
  """
  def get_country_by_name(country_name) do
    try do
      # Start the countries service if not already started
      {:ok, _} = BCApis.Countries.start(true)
      
      # Get all countries and find by name
      countries = BCApis.Countries.all_countries()
      
      case countries do
        country_names when is_list(country_names) ->
          # The all_countries function returns only names, we need to get the full data
          # Let's try to get the country by searching through the internal state
          {:error, "Function needs to be updated to return full country data"}
        
        _ -> {:error, "Countries service unavailable"}
      end
    rescue
      _ -> {:error, "Countries service unavailable"}
    end
  end
  
  @doc """
  Get country flag emoji by name
  """
  def get_country_flag(country_name) do
    try do
      # Start the countries service if not already started
      {:ok, _} = BCApis.Countries.start(true)
      
      # Use a more direct approach to get the flag
      case get_country_data_by_name(country_name) do
        {:ok, country_data} ->
          # Extract the flag emoji from the country data
          flag = country_data["flag"] || "🏳️"
          {:ok, flag}
        
        {:error, _} -> {:ok, "🏳️"}
      end
    rescue
      _ -> {:ok, "🏳️"}
    end
  end
  
  @doc """
  Get full country data by name - internal helper
  """
  defp get_country_data_by_name(country_name) do
    try do
      # Read the countries JSON file directly
      case :code.priv_dir(:apis) do
        {:error, _} -> {:error, "Could not find priv directory"}
        app_path ->
          file_path = Path.join([app_path, "countries.json"])
          case File.read(file_path) do
            {:error, _} -> {:error, "Could not read countries file"}
            {:ok, content} ->
              {:ok, countries} = Jason.decode(content)
              
              # Find the country by name
              country = Enum.find(countries, fn country ->
                country["name"]["common"] == country_name
              end)
              
              if country do
                {:ok, country}
              else
                {:error, "Country not found"}
              end
          end
      end
    rescue
      _ -> {:error, "Failed to read country data"}
    end
  end

  @doc """
  Parse location coordinates from a greenhouse location string
  """
  def parse_location_coordinates(location) when is_binary(location) do
    case String.split(location, ",") do
      [lat_str, lon_str] ->
        with {lat, ""} <- Float.parse(String.trim(lat_str)),
             {lon, ""} <- Float.parse(String.trim(lon_str)) do
          {:ok, {lat, lon}}
        else
          _ -> {:error, :invalid_coordinates}
        end
      
      _ -> {:error, :invalid_format}
    end
  end
  
  def parse_location_coordinates(_), do: {:error, :invalid_location}

  @doc """
  Get enhanced greenhouse data with location information
  """
  def get_greenhouse_with_location(greenhouse_id) do
    case get_greenhouse_state(greenhouse_id) do
      {:ok, state} ->
        case GreenhouseTycoon.Repo.get_by(GreenhouseTycoon.Greenhouse, greenhouse_id: greenhouse_id) do
          greenhouse when not is_nil(greenhouse) ->
            # Parse coordinates
            coordinates = case parse_location_coordinates(greenhouse.location) do
              {:ok, {lat, lon}} -> %{latitude: lat, longitude: lon}
              _ -> %{latitude: nil, longitude: nil}
            end
            
            enhanced_state = Map.merge(state, coordinates)
            {:ok, enhanced_state}
          
          _ -> {:ok, state}
        end
      
      error -> error
    end
  end

  @doc """
  Gets the current state of a greenhouse.
  """
  @spec get_greenhouse_state(String.t()) :: {:ok, map()} | {:error, term()}
  def get_greenhouse_state(greenhouse_id) do
    case GreenhouseTycoon.Repo.get_by(GreenhouseTycoon.Greenhouse, greenhouse_id: greenhouse_id) do
      nil ->
        {:error, :not_found}

      read_model ->
        {:ok,
         %{
           current_temperature: read_model.current_temperature || 0,
           current_humidity: read_model.current_humidity || 0,
           current_light: read_model.current_light || 0,
           desired_temperature: read_model.target_temperature,
           desired_humidity: read_model.target_humidity,
           desired_light: read_model.target_light,
           city: read_model.city,
           country: read_model.country,
           last_updated: read_model.updated_at,
           event_count: read_model.event_count,
           status: read_model.status
         }}
    end
  end

  @doc """
  Gets recent events for a greenhouse.
  """
  @spec get_greenhouse_events(String.t(), integer()) :: [map()] | nil
  def get_greenhouse_events(greenhouse_id, limit) do
    require Logger

    # Get the stream prefix from configuration
    event_store_config =
      Application.get_env(:greenhouse_tycoon, GreenhouseTycoon.CommandedApp)[:event_store]

    stream_prefix = Keyword.get(event_store_config, :stream_prefix, "")
    store_id = Keyword.get(event_store_config, :store_id, :default)

    # Construct the event stream ID using the configured prefix
    event_stream_id = stream_prefix <> greenhouse_id

    Logger.info("API: Constructed event_stream_id for greenhouse #{greenhouse_id}: #{event_stream_id}")

    # Read backward from the end of the stream to get the most recent events
    # First, get the stream version to find the last event version
    case ExESDBGater.API.get_version(store_id, event_stream_id) do
      {:ok, last_version} when is_integer(last_version) and last_version >= 0 ->
        # Now read backward from the last event
        case ExESDBGater.API.get_events(store_id, event_stream_id, last_version, limit, :backward) do
          {:ok, events} when is_list(events) ->
            Logger.debug("API: Found #{length(events)} events for greenhouse #{greenhouse_id}")
            
            # Events are already in reverse chronological order (newest first) when reading backward
            # No need to reverse them
            
            # Convert ExESDB.Schema.EventRecord to a simplified map format for the UI
            converted_events = Enum.map(events, fn event ->
                # Convert struct data to map format for UI consumption
                data =
                  case event.data do
                    %{__struct__: struct_name} = struct_data ->
                      Logger.debug("API: Converting struct #{struct_name} to map")
                      # Convert struct to map
                      map_data = Map.from_struct(struct_data)
                      Logger.debug("API: Converted data: #{inspect(map_data)}")
                      map_data

                    map_data when is_map(map_data) ->
                      Logger.debug("API: Event data is already a map")
                      map_data

                    other ->
                      Logger.debug("API: Event data is other type: #{inspect(other)}")
                      other
                  end

                %{
                  event_id: event.event_id,
                  event_type: event.event_type,
                  data: data,
                  metadata: event.metadata,
                  created: event.created,
                  event_number: event.event_number
                }
              end)

            converted_events

          {:error, :stream_not_found} ->
            Logger.debug("API: Stream #{event_stream_id} not found")
            []

          {:error, reason} ->
            Logger.warning(
              "API: Failed to read events for stream #{event_stream_id}: #{inspect(reason)}"
            )
            []

          resp ->
            Logger.warning(
              "API: Unexpected response when reading events for stream #{event_stream_id}...response: #{inspect(resp)}"
            )
            []
        end

      {:ok, -1} ->
        Logger.debug("API: Stream #{event_stream_id} is empty")
        []

      {:error, :stream_not_found} ->
        Logger.debug("API: Stream #{event_stream_id} not found")
        []

      {:error, reason} ->
        Logger.warning(
          "API: Failed to get stream version for #{event_stream_id}: #{inspect(reason)}"
        )
        []

      resp ->
        Logger.warning(
          "API: Unexpected response when getting stream version for #{event_stream_id}...response: #{inspect(resp)}"
        )
        []
    end
  end

  

  

  

  

  @doc """
  Get the status of all projections.
  """
  @spec get_projections_status() :: {:ok, list()} | {:error, term()}
  def get_projections_status do
    require Logger
    Logger.info("API: Getting projections status")
    
    case GreenhouseTycoon.Projections.ProjectionsSystem.projection_status() do
      {:ok, projections} ->
        Logger.info("API: Found #{length(projections)} projections")
        {:ok, projections}
        
      {:error, reason} = error ->
        Logger.error("API: Failed to get projections status: #{inspect(reason)}")
        error
    end
  end
  
  @doc """
  Restart a specific projection.
  """
  @spec restart_projection(atom()) :: :ok | {:error, term()}
  def restart_projection(projection_module) when is_atom(projection_module) do
    require Logger
    Logger.info("API: Restarting projection #{projection_module}")
    
    case GreenhouseTycoon.Projections.ProjectionsSystem.restart_projection(projection_module) do
      :ok ->
        Logger.info("API: Successfully restarted projection #{projection_module}")
        :ok
        
      {:error, reason} = error ->
        Logger.error("API: Failed to restart projection #{projection_module}: #{inspect(reason)}")
        error
    end
  end
  
  @doc """
  Get projections health summary.
  """
  @spec get_projections_health() :: map()
  def get_projections_health do
    GreenhouseTycoon.Projections.ProjectionsSystem.running_projections_count()
  end

  @doc """
  Rebuild event handlers (Ecto projections).
  
  This truncates the database tables and uses Commanded's built-in reset functionality to 
  restart Ecto projections from their configured start position. This triggers
  automatic replay of events from the event store, rebuilding the database read models from scratch.
  This is the proper way to rebuild read models in an event-sourced system.
  """
  @spec rebuild_event_handlers() :: {:ok, map()} | {:error, term()}
  def rebuild_event_handlers do
    require Logger
    Logger.info("API: Rebuilding Ecto projections using Commanded's reset functionality")
    
    try do
      # Step 1: Clear the database tables to ensure clean rebuild
      Logger.info("API: Truncating greenhouse table before rebuilding projections")
      case GreenhouseTycoon.Repo.delete_all(GreenhouseTycoon.Greenhouse) do
        {count, _} -> 
          Logger.info("API: Deleted #{count} greenhouse records")
      end
      
      # Step 2: Get list of Ecto projections to reset
      ecto_projections = [
        "InitializedToGreenhouseEctoV1",
        "TemperatureMeasuredToGreenhouseEctoV1", 
        "HumidityMeasuredToGreenhouseEctoV1",
        "LightMeasuredToGreenhouseEctoV1",
        "TargetTemperatureSetToGreenhouseEctoV1",
        "TargetHumiditySetToGreenhouseEctoV1",
        "TargetLightSetToGreenhouseEctoV1"
      ]
      
      # Step 3: Reset each Ecto projection using Commanded's registry
      reset_results = Enum.map(ecto_projections, fn projection_name ->
        Logger.info("API: Resetting Ecto projection: #{projection_name}")
        
        # Get the projection's registered name and PID
        registry_name = Commanded.Projections.Ecto.name(GreenhouseTycoon.CommandedApp, projection_name)
        
        case Commanded.Registration.whereis_name(GreenhouseTycoon.CommandedApp, registry_name) do
          :undefined ->
            Logger.warning("API: Projection #{projection_name} not found in registry")
            {projection_name, {:error, :not_found}}
            
          pid when is_pid(pid) ->
            Logger.info("API: Sending reset message to projection #{projection_name} (PID: #{inspect(pid)})")
            send(pid, :reset)
            {projection_name, :ok}
            
          other ->
            Logger.error("API: Unexpected registry response for #{projection_name}: #{inspect(other)}")
            {projection_name, {:error, :unexpected_response}}
        end
      end)
      
      # Step 4: Reset subscription tracking to clear strong consistency state
      Logger.info("API: Resetting subscription tracking")
      case Commanded.Subscriptions.reset(GreenhouseTycoon.CommandedApp) do
        :ok -> 
          Logger.info("API: Subscription tracking reset successfully")
        error -> 
          Logger.error("API: Failed to reset subscription tracking: #{inspect(error)}")
      end
      
      # Step 5: Check results and prepare response
      {successful, failed} = Enum.split_with(reset_results, fn {_projection, result} -> result == :ok end)
      
      # Step 6: Wait for projections to process events and rebuild database
      Logger.info("API: Waiting for Ecto projections to rebuild from events...")
      Process.sleep(3000)  # Give projections time to replay events
      
      # Step 7: Get final database status
      db_size = length(GreenhouseTycoon.Repo.all(GreenhouseTycoon.Greenhouse))
      
      response = %{
        status: if(length(failed) == 0, do: :success, else: :partial_success),
        db_size: db_size,
        projections_reset: length(successful),
        projections_failed: length(failed),
        successful_projections: Enum.map(successful, fn {projection, _} -> projection end),
        failed_projections: Enum.map(failed, fn {projection, error} -> {projection, error} end),
        method: :ecto_projections_reset,
        timestamp: DateTime.utc_now()
      }
      
      if length(failed) == 0 do
        Logger.info("API: Ecto projections reset successfully. Database now contains #{db_size} items")
        {:ok, response}
      else
        Logger.warning("API: Ecto projections partially reset. #{length(successful)} succeeded, #{length(failed)} failed")
        {:ok, response}
      end
      
    rescue
      error ->
        Logger.error("API: Exception during Ecto projection reset: #{inspect(error)}")
        {:error, {:reset_exception, error}}
    end
  end
  
  @doc """
  Get event handler status (Ecto projections status).
  
  Returns the current status of the database and Ecto projections,
  which represents the state of the read models built from events.
  """
  @spec get_event_handler_status() :: {:ok, map()}
  def get_event_handler_status do
    greenhouses = GreenhouseTycoon.Repo.all(GreenhouseTycoon.Greenhouse)
    
    {:ok, %{
      db_size: length(greenhouses),
      greenhouse_count: length(greenhouses),
      greenhouse_ids: Enum.map(greenhouses, & &1.greenhouse_id),
      status: :active,
      timestamp: DateTime.utc_now()
    }}
  end
end
