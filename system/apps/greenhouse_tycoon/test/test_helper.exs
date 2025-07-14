ExUnit.start()

# Start required applications for testing in proper order
# ExESDB Gater must start before ExESDB since ExESDB depends on it
{:ok, _} = Application.ensure_all_started(:ex_esdb_gater)
{:ok, _} = Application.ensure_all_started(:ex_esdb)
{:ok, _} = Application.ensure_all_started(:commanded)

# Start the greenhouse_tycoon application
{:ok, _} = Application.ensure_all_started(:greenhouse_tycoon)

# Set up Ecto sandbox for database testing
if Code.ensure_loaded?(GreenhouseTycoon.Repo) do
  Ecto.Adapters.SQL.Sandbox.mode(GreenhouseTycoon.Repo, :manual)
end
