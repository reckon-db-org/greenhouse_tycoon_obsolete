defmodule GreenhouseTycoon.Aggregate do
  @moduledoc """
  Greenhouse aggregate for event sourcing.

  This aggregate handles commands related to greenhouse regulation
  and maintains the current state of a greenhouse.
  
  Following the Reckon vertical slicing architecture, this aggregate delegates
  command and event handling to specialized handlers in each vertical slice.
  """
  
  require Logger

  @type t :: %__MODULE__{
          greenhouse_id: String.t() | nil,
          name: String.t() | nil,
          location: String.t() | nil,
          city: String.t(),
          country: String.t(),
          target_temperature: float() | nil,
          target_humidity: float() | nil,
          target_light: float() | nil,
          current_temperature: float() | nil,
          current_humidity: float() | nil,
          current_light: float() | nil,
          created_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct [
    :greenhouse_id,
    :name,
    :location,
    :city,
    :country,
    :target_temperature,
    :target_humidity,
    :target_light,
    :current_temperature,
    :current_humidity,
    :current_light,
    :created_at,
    :updated_at
  ]

  # Command Handlers - Delegating to vertical slice handlers

  def execute(%__MODULE__{} = greenhouse, %GreenhouseTycoon.InitializeGreenhouse.CommandV1{} = command) do
    GreenhouseTycoon.InitializeGreenhouse.MaybeInitializeGreenhouseV1.execute(greenhouse, command)
  end

  def execute(%__MODULE__{} = greenhouse, %GreenhouseTycoon.SetTargetTemperature.CommandV1{} = command) do
    GreenhouseTycoon.SetTargetTemperature.MaybeSetTargetTemperatureV1.execute(greenhouse, command)
  end

  def execute(%__MODULE__{} = greenhouse, %GreenhouseTycoon.SetTargetHumidity.CommandV1{} = command) do
    GreenhouseTycoon.SetTargetHumidity.MaybeSetTargetHumidityV1.execute(greenhouse, command)
  end

  def execute(%__MODULE__{} = greenhouse, %GreenhouseTycoon.SetTargetLight.CommandV1{} = command) do
    GreenhouseTycoon.SetTargetLight.MaybeSetTargetLightV1.execute(greenhouse, command)
  end

  def execute(%__MODULE__{} = greenhouse, %GreenhouseTycoon.MeasureTemperature.CommandV1{} = command) do
    GreenhouseTycoon.MeasureTemperature.MaybeMeasureTemperatureV1.execute(greenhouse, command)
  end

  def execute(%__MODULE__{} = greenhouse, %GreenhouseTycoon.MeasureHumidity.CommandV1{} = command) do
    GreenhouseTycoon.MeasureHumidity.MaybeMeasureHumidityV1.execute(greenhouse, command)
  end

  def execute(%__MODULE__{} = greenhouse, %GreenhouseTycoon.MeasureLight.CommandV1{} = command) do
    GreenhouseTycoon.MeasureLight.MaybeMeasureLightV1.execute(greenhouse, command)
  end

  def execute(%__MODULE__{greenhouse_id: nil} = state, command) do
    Logger.error("Greenhouse.execute: greenhouse_not_found - state has nil greenhouse_id")
    Logger.error("Greenhouse.execute: State: #{inspect(state)}")
    Logger.error("Greenhouse.execute: Command: #{inspect(command)}")
    {:error, :greenhouse_not_found}
  end

  def execute(%__MODULE__{} = greenhouse, command) do
    command_name = command.__struct__ |> to_string() |> String.split(".") |> List.last()
    
    Logger.error("Greenhouse.execute: Unhandled command type: #{command_name}")
    Logger.error("Greenhouse.execute: Command: #{inspect(command)}")
    Logger.error("Greenhouse.execute: This indicates a missing command handler - check implementation")
    
    {:error, :unhandled_command}
  end

  # State Mutators - Delegating to vertical slice aggregate handlers

  def apply(%__MODULE__{} = greenhouse, %GreenhouseTycoon.InitializeGreenhouse.EventV1{} = event) do
    GreenhouseTycoon.InitializeGreenhouse.InitializedToAggregateV1.apply(greenhouse, event)
  end

  def apply(%__MODULE__{} = greenhouse, %GreenhouseTycoon.SetTargetTemperature.EventV1{} = event) do
    GreenhouseTycoon.SetTargetTemperature.TargetTemperatureSetToAggregateV1.apply(greenhouse, event)
  end

  def apply(%__MODULE__{} = greenhouse, %GreenhouseTycoon.SetTargetHumidity.EventV1{} = event) do
    GreenhouseTycoon.SetTargetHumidity.TargetHumiditySetToAggregateV1.apply(greenhouse, event)
  end

  def apply(%__MODULE__{} = greenhouse, %GreenhouseTycoon.SetTargetLight.EventV1{} = event) do
    GreenhouseTycoon.SetTargetLight.TargetLightSetToAggregateV1.apply(greenhouse, event)
  end

  def apply(%__MODULE__{} = greenhouse, %GreenhouseTycoon.MeasureTemperature.EventV1{} = event) do
    GreenhouseTycoon.MeasureTemperature.TemperatureMeasuredToAggregateV1.apply(greenhouse, event)
  end

  def apply(%__MODULE__{} = greenhouse, %GreenhouseTycoon.MeasureHumidity.EventV1{} = event) do
    GreenhouseTycoon.MeasureHumidity.HumidityMeasuredToAggregateV1.apply(greenhouse, event)
  end

  def apply(%__MODULE__{} = greenhouse, %GreenhouseTycoon.MeasureLight.EventV1{} = event) do
    GreenhouseTycoon.MeasureLight.LightMeasuredToAggregateV1.apply(greenhouse, event)
  end

  # Add a fallback error handler for unrecognized events
  def apply(%__MODULE__{} = greenhouse, event) do
    Logger.error("Greenhouse.apply: Unhandled event type: #{inspect(event.__struct__)}")
    Logger.error("Greenhouse.apply: Event: #{inspect(event)}")
    Logger.error("Greenhouse.apply: This indicates a missing event handler - check implementation")
    greenhouse
  end
end
