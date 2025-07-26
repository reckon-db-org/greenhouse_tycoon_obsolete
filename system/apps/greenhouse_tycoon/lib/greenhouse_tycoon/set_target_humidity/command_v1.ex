defmodule GreenhouseTycoon.SetTargetHumidity.CommandV1 do
  @moduledoc """
  Command to set the target humidity for a greenhouse.
  
  This command is triggered when a user wants to adjust the target humidity
  setting for environmental control in a specific greenhouse.
  """
  
  @derive Jason.Encoder
  defstruct [
    :greenhouse_id,
    :target_humidity,
    :set_by,
    :requested_at
  ]
  
  @type t :: %__MODULE__{
    greenhouse_id: String.t(),
    target_humidity: float(),
    set_by: String.t() | nil,
    requested_at: DateTime.t()
  }
  
  @doc """
  Creates a new SetTargetHumidity command.
  """
  def new(attrs) do
    attrs = Map.put_new(attrs, :requested_at, DateTime.utc_now())
    {:ok, struct(__MODULE__, attrs)}
  end
  
  @doc """
  Validates the command according to business rules.
  """
  def valid?(%__MODULE__{} = command) do
    with :ok <- validate_greenhouse_id(command.greenhouse_id),
         :ok <- validate_target_humidity(command.target_humidity) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  defp validate_greenhouse_id(nil), do: {:error, :greenhouse_id_required}
  defp validate_greenhouse_id(""), do: {:error, :greenhouse_id_required}
  defp validate_greenhouse_id(_), do: :ok
  
  defp validate_target_humidity(nil), do: {:error, :target_humidity_required}
  defp validate_target_humidity(humidity) when is_number(humidity) and humidity >= 0 and humidity <= 100, do: :ok
  defp validate_target_humidity(_), do: {:error, :invalid_target_humidity}
end
