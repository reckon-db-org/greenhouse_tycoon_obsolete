defmodule GreenhouseTycoon.Repo.Migrations.CreateProjectionVersions do
  use Ecto.Migration

  def change do
    create table(:projection_versions) do
      add :projection_name, :string, null: false
      add :last_seen_event_number, :bigint, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:projection_versions, [:projection_name])
  end
end
