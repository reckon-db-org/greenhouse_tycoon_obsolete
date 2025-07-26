defmodule GreenhouseTycoon.MeasureTemperature.CommandV1 do
  @moduledoc """
  Command to record a temperature measurement for a greenhouse.
  
  This command is triggered when a sensor records a temperature reading
  or when manual measurements are taken.
  """
  
  @derive Jason.Encoder
  defstruct [
    :greenhouse_id,
    :temperature,
    :measured_at,
    :sensor_id,
    :measurement_type
  ]
  
  @type measurement_type :: :sensor | :manual
  
  @type t :: %__MODULE__{
    greenhouse_id: String.t(),
    temperature: float(),
    measured_at: DateTime.t(),
    sensor_id: String.t() | nil,
    measurement_type: measurement_type()
  }
  
  @doc """
  Creates a new MeasureTemperature command.
  """
  def new(attrs) do
    attrs = 
      attrs
      |> Map.put_new(:measured_at, DateTime.utc_now())
      |> Map.put_new(:measurement_type, :sensor)
    
    {:ok, struct(__MODULE__, attrs)}
  end
  
  @doc """
  Validates the command according to business rules.
  """
  def valid?(%__MODULE__{} = command) do
    with :ok <- validate_greenhouse_id(command.greenhouse_id),
         :ok <- validate_temperature(command.temperature),
         :ok <- validate_measured_at(command.measured_at),
         :ok <- validate_measurement_type(command.measurement_type) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  defp validate_greenhouse_id(nil), do: {:error, :greenhouse_id_required}
  defp validate_greenhouse_id(""), do: {:error, :greenhouse_id_required}
  defp validate_greenhouse_id(_), do: :ok
  
  defp validate_temperature(nil), do: {:error, :temperature_required}
  defp validate_temperature(temp) when is_number(temp) and temp >= -100 and temp <= 100, do: :ok
  defp validate_temperature(_), do: {:error, :invalid_temperature}
  
  defp validate_measured_at(nil), do: {:error, :measured_at_required}
  defp validate_measured_at(%DateTime{}), do: :ok
  defp validate_measured_at(_), do: {:error, :invalid_measured_at}
  
  defp validate_measurement_type(type) when type in [:sensor, :manual], do: :ok
  defp validate_measurement_type(_), do: {:error, :invalid_measurement_type}
end
