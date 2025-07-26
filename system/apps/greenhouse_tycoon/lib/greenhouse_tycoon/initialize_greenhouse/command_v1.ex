defmodule GreenhouseTycoon.InitializeGreenhouse.CommandV1 do
  @moduledoc """
  Command to initialize a new greenhouse with basic configuration.
  
  This command is triggered when a user wants to create a new greenhouse
  with location information and optional environmental targets.
  """
  
  @derive Jason.Encoder
  defstruct [
    :greenhouse_id,
    :name,
    :location,
    :city,
    :country,
    :target_temperature,
    :target_humidity,
    :target_light,
    :requested_at
  ]
  
  @type t :: %__MODULE__{
    greenhouse_id: String.t(),
    name: String.t(),
    location: String.t(),
    city: String.t(),
    country: String.t(),
    target_temperature: float() | nil,
    target_humidity: float() | nil,
    target_light: float() | nil,
    requested_at: DateTime.t()
  }
  
  @doc """
  Creates a new InitializeGreenhouse command.
  """
  def new(attrs) do
    attrs = Map.put_new(attrs, :requested_at, DateTime.utc_now())
    struct(__MODULE__, attrs)
  end
  
  @doc """
  Validates the command according to business rules.
  """
  def valid?(%__MODULE__{} = command) do
    with :ok <- validate_greenhouse_id(command.greenhouse_id),
         :ok <- validate_name(command.name),
         :ok <- validate_location(command.location),
         :ok <- validate_city(command.city),
         :ok <- validate_country(command.country),
         :ok <- validate_target_temperature(command.target_temperature),
         :ok <- validate_target_humidity(command.target_humidity),
         :ok <- validate_target_light(command.target_light) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  defp validate_greenhouse_id(nil), do: {:error, :greenhouse_id_required}
  defp validate_greenhouse_id(""), do: {:error, :greenhouse_id_required}
  defp validate_greenhouse_id(_), do: :ok
  
  defp validate_name(nil), do: {:error, :name_required}
  defp validate_name(""), do: {:error, :name_required}
  defp validate_name(_), do: :ok
  
  defp validate_location(nil), do: {:error, :location_required}
  defp validate_location(""), do: {:error, :location_required}
  defp validate_location(_), do: :ok
  
  defp validate_city(nil), do: {:error, :city_required}
  defp validate_city(""), do: {:error, :city_required}
  defp validate_city(_), do: :ok
  
  defp validate_country(nil), do: {:error, :country_required}
  defp validate_country(""), do: {:error, :country_required}
  defp validate_country(_), do: :ok
  
  defp validate_target_temperature(nil), do: :ok
  defp validate_target_temperature(temp) when is_number(temp) and temp >= -50 and temp <= 80, do: :ok
  defp validate_target_temperature(_), do: {:error, :invalid_target_temperature}
  
  defp validate_target_humidity(nil), do: :ok
  defp validate_target_humidity(humidity) when is_number(humidity) and humidity >= 0 and humidity <= 100, do: :ok
  defp validate_target_humidity(_), do: {:error, :invalid_target_humidity}
  
  defp validate_target_light(nil), do: :ok
  defp validate_target_light(light) when is_number(light) and light >= 0 and light <= 100000, do: :ok
  defp validate_target_light(_), do: {:error, :invalid_target_light}
end
