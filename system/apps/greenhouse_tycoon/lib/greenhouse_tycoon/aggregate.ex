defmodule GreenhouseTycoon.Greenhouse do
  @moduledoc """
  Greenhouse aggregate for event sourcing.

  This aggregate handles commands related to greenhouse regulation
  and maintains the current state of a greenhouse.
  """

  alias GreenhouseTycoon.Commands.{
    InitializeGreenhouse,
    SetTargetTemperature,
    SetTargetHumidity,
    SetTargetLight,
    MeasureTemperature,
    MeasureHumidity,
    MeasureLight
  }

  alias GreenhouseTycoon.Events.{
    GreenhouseInitialized,
    TemperatureSet,
    HumiditySet,
    LightSet,
    TemperatureMeasured,
    HumidityMeasured,
    LightMeasured
  }

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
    require Logger
    Logger.error("Greenhouse.execute: greenhouse_not_found - state has nil greenhouse_id")
    Logger.error("Greenhouse.execute: State: #{inspect(state)}")
    Logger.error("Greenhouse.execute: Command: #{inspect(command)}")
    {:error, :greenhouse_not_found}
  end

  def execute(%__MODULE__{} = greenhouse, %SetTargetTemperature{greenhouse_id: greenhouse_id} = command)
      when greenhouse.greenhouse_id == greenhouse_id do
    %TemperatureSet{
      greenhouse_id: command.greenhouse_id,
      target_temperature: command.target_temperature,
      previous_temperature: greenhouse.target_temperature,
      set_by: command.set_by,
      set_at: DateTime.utc_now()
    }
  end

  def execute(%__MODULE__{} = greenhouse, %SetTargetHumidity{greenhouse_id: greenhouse_id} = command)
      when greenhouse.greenhouse_id == greenhouse_id do
    %HumiditySet{
      greenhouse_id: command.greenhouse_id,
      target_humidity: command.target_humidity,
      previous_humidity: greenhouse.target_humidity,
      set_by: command.set_by,
      set_at: DateTime.utc_now()
    }
  end

  def execute(%__MODULE__{} = greenhouse, %SetTargetLight{greenhouse_id: greenhouse_id} = command)
      when greenhouse.greenhouse_id == greenhouse_id do
    require Logger

    Logger.info(
      "Greenhouse.execute: SetTargetLight for #{greenhouse_id}, state greenhouse_id: #{greenhouse.greenhouse_id}"
    )

    %LightSet{
      greenhouse_id: command.greenhouse_id,
      target_light: command.target_light,
      previous_light: greenhouse.target_light,
      set_by: command.set_by,
      set_at: DateTime.utc_now()
    }
  end

  def execute(
        %__MODULE__{} = greenhouse,
        %MeasureTemperature{greenhouse_id: greenhouse_id} = command
      )
      when greenhouse.greenhouse_id == greenhouse_id do
    require Logger

    Logger.info(
      "Greenhouse.execute: MeasureTemperature for #{greenhouse_id}, temperature: #{command.temperature}°C"
    )

    %TemperatureMeasured{
      greenhouse_id: command.greenhouse_id,
      temperature: command.temperature,
      measured_at: command.measured_at
    }
  end

  def execute(
        %__MODULE__{} = greenhouse,
        %MeasureHumidity{greenhouse_id: greenhouse_id} = command
      )
      when greenhouse.greenhouse_id == greenhouse_id do
    require Logger

    Logger.info(
      "Greenhouse.execute: MeasureHumidity for #{greenhouse_id}, humidity: #{command.humidity}%"
    )

    %HumidityMeasured{
      greenhouse_id: command.greenhouse_id,
      humidity: command.humidity,
      measured_at: command.measured_at
    }
  end

  def execute(%__MODULE__{} = greenhouse, %MeasureLight{greenhouse_id: greenhouse_id} = command)
      when greenhouse.greenhouse_id == greenhouse_id do
    require Logger

    Logger.info(
      "Greenhouse.execute: MeasureLight for #{greenhouse_id}, light: #{command.light} lumens"
    )

    %LightMeasured{
      greenhouse_id: command.greenhouse_id,
      light: command.light,
      measured_at: command.measured_at
    }
  end

  def execute(%__MODULE__{} = greenhouse, command) do
    require Logger
    command_name = command.__struct__ |> to_string() |> String.split(".") |> List.last()
    command_greenhouse_id = Map.get(command, :greenhouse_id, "unknown")

    Logger.error("Greenhouse.execute: Command #{command_name} failed - greenhouse_id mismatch")
    Logger.error("Greenhouse.execute: Command greenhouse_id: #{command_greenhouse_id}")
    Logger.error("Greenhouse.execute: State greenhouse_id: #{inspect(greenhouse.greenhouse_id)}")
    Logger.error("Greenhouse.execute: Full state: #{inspect(greenhouse)}")
    Logger.error("Greenhouse.execute: Full command: #{inspect(command)}")

    {:error, :greenhouse_id_mismatch}
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

  def apply(%__MODULE__{} = greenhouse, %TemperatureSet{} = event) do
    require Logger

    Logger.info(
      "Greenhouse.apply: TemperatureSet for #{event.greenhouse_id}, target: #{event.target_temperature}°C"
    )

    %__MODULE__{
      greenhouse
      | target_temperature: event.target_temperature,
        updated_at: event.set_at
    }
  end

  def apply(%__MODULE__{} = greenhouse, %HumiditySet{} = event) do
    require Logger

    Logger.info(
      "Greenhouse.apply: HumiditySet for #{event.greenhouse_id}, target: #{event.target_humidity}%"
    )

    %__MODULE__{greenhouse | target_humidity: event.target_humidity, updated_at: event.set_at}
  end

  def apply(%__MODULE__{} = greenhouse, %LightSet{} = event) do
    require Logger

    Logger.info(
      "Greenhouse.apply: LightSet for #{event.greenhouse_id}, target: #{event.target_light} lumens"
    )

    %__MODULE__{greenhouse | target_light: event.target_light, updated_at: event.set_at}
  end

  def apply(%__MODULE__{} = greenhouse, %TemperatureMeasured{} = event) do
    require Logger

    Logger.info(
      "Greenhouse.apply: TemperatureMeasured for #{event.greenhouse_id}, temperature: #{event.temperature}°C"
    )

    %__MODULE__{
      greenhouse
      | current_temperature: event.temperature,
        updated_at: event.measured_at
    }
  end

  def apply(%__MODULE__{} = greenhouse, %HumidityMeasured{} = event) do
    require Logger

    Logger.info(
      "Greenhouse.apply: HumidityMeasured for #{event.greenhouse_id}, humidity: #{event.humidity}%"
    )

    %__MODULE__{greenhouse | current_humidity: event.humidity, updated_at: event.measured_at}
  end

  def apply(%__MODULE__{} = greenhouse, %LightMeasured{} = event) do
    require Logger

    Logger.info(
      "Greenhouse.apply: LightMeasured for #{event.greenhouse_id}, light: #{event.light} lumens"
    )

    %__MODULE__{greenhouse | current_light: event.light, updated_at: event.measured_at}
  end
end
