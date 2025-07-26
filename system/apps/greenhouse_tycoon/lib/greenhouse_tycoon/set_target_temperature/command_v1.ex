defmodule GreenhouseTycoon.SetTargetTemperature.CommandV1 do
  @moduledoc """
  Command to set the target temperature for a greenhouse.
  
  This command is triggered when a user wants to adjust the target temperature
  setting for environmental control in a specific greenhouse.
  """
  
  @derive Jason.Encoder
  defstruct [
    :greenhouse_id,
    :target_temperature,
    :set_by,
    :requested_at
  ]
  
  @type t :: %__MODULE__{
    greenhouse_id: String.t(),
    target_temperature: float(),
    set_by: String.t() | nil,
    requested_at: DateTime.t()
  }
  
  @doc """
  Creates a new SetTargetTemperature command.
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
         :ok <- validate_target_temperature(command.target_temperature) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  defp validate_greenhouse_id(nil), do: {:error, :greenhouse_id_required}
  defp validate_greenhouse_id(""), do: {:error, :greenhouse_id_required}
  defp validate_greenhouse_id(_), do: :ok
  
  defp validate_target_temperature(nil), do: {:error, :target_temperature_required}
  defp validate_target_temperature(temp) when is_number(temp) and temp >= -50 and temp <= 80, do: :ok
  defp validate_target_temperature(_), do: {:error, :invalid_target_temperature}
end
