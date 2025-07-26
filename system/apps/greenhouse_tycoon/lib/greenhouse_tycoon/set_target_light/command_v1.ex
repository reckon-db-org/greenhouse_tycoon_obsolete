defmodule GreenhouseTycoon.SetTargetLight.CommandV1 do
  @moduledoc """
  Command to set the target light level for a greenhouse.
  
  This command is triggered when a user wants to adjust the target light
  setting for environmental control in a specific greenhouse.
  """
  
  @derive Jason.Encoder
  defstruct [
    :greenhouse_id,
    :target_light,
    :set_by,
    :requested_at
  ]
  
  @type t :: %__MODULE__{
    greenhouse_id: String.t(),
    target_light: float(),
    set_by: String.t() | nil,
    requested_at: DateTime.t()
  }
  
  @doc """
  Creates a new SetTargetLight command.
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
         :ok <- validate_target_light(command.target_light) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  defp validate_greenhouse_id(nil), do: {:error, :greenhouse_id_required}
  defp validate_greenhouse_id(""), do: {:error, :greenhouse_id_required}
  defp validate_greenhouse_id(_), do: :ok
  
  defp validate_target_light(nil), do: {:error, :target_light_required}
  defp validate_target_light(light) when is_number(light) and light >= 0 and light <= 100000, do: :ok
  defp validate_target_light(_), do: {:error, :invalid_target_light}
end
