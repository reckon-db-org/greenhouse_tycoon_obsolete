defmodule GreenhouseTycoon.Repo.Migrations.CreateGreenhouses do
  use Ecto.Migration

  def up do
    create table(:greenhouses, primary_key: false) do
      add :greenhouse_id, :string, primary_key: true, null: false
      add :name, :string, null: false
      add :location, :string
      add :city, :string
      add :country, :string
      
      # Current measurements
      add :current_temperature, :float
      add :current_humidity, :float
      add :current_light, :float
      
      # Target settings
      add :target_temperature, :float
      add :target_humidity, :float
      add :target_light, :float
      
      # Status tracking
      add :event_count, :integer, default: 0, null: false
      add :status, :integer
     
      timestamps(type: :utc_datetime)
    end

    create unique_index(:greenhouses, [:greenhouse_id])
  end

  def down do
    drop table(:greenhouses)
  end
end
