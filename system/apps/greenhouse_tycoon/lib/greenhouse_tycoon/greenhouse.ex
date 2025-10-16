defmodule GreenhouseTycoon.Greenhouse do
  @moduledoc """
  Read model representing the current state of a greenhouse.

  This is the global/default read model that represents the complete state
  of the greenhouse regulation business process.
  """

  use Ecto.Schema
  import Ecto.Changeset

  defmodule Status do
    def unknown, do: 0
    def initialized, do: 1
    def inactive, do: 2
    def active, do: 4
  end

  @primary_key false
  schema "greenhouses" do
    field :greenhouse_id, :string, primary_key: true
    field :name, :string
    field :location, :string
    field :city, :string
    field :country, :string
    field :current_temperature, :float
    field :current_humidity, :float
    field :current_light, :float
    field :target_temperature, :float
    field :target_humidity, :float
    field :target_light, :float
    field :event_count, :integer, default: 0
    field :status, :integer
    
    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for updating greenhouse data.
  """
  def changeset(greenhouse, attrs) do
    greenhouse
    |> cast(attrs, [
      :greenhouse_id,
      :name,
      :location,
      :city,
      :country,
      :current_temperature,
      :current_humidity,
      :current_light,
      :target_temperature,
      :target_humidity,
      :target_light,
      :event_count,
      :status
    ])
    |> validate_required([:greenhouse_id, :name])
    |> unique_constraint(:greenhouse_id)
  end

  @doc """
  Calculates the status of a greenhouse based on its target settings.
  """
  def calculate_status(%__MODULE__{
        target_temperature: nil,
        target_humidity: nil,
        target_light: nil
      }),
      do: :inactive

  def calculate_status(_), do: :active
end
