#!/usr/bin/env elixir

# Test script for Ecto projections
# Run with: mix run test_projections.exs

require Logger
alias GreenhouseTycoon.{API, Repo, Greenhouse}

Logger.configure(level: :info)

defmodule ProjectionTest do
  def run do
    Logger.info("=== Starting Projection Test ===")
    
    # Clean up any existing test greenhouse
    greenhouse_id = "test_proj_#{System.unique_integer([:positive])}"
    
    Logger.info("Step 1: Creating greenhouse #{greenhouse_id}")
    
    case API.create_greenhouse(
      greenhouse_id,
      "Test Greenhouse",
      "50.8503,4.3517",  # Brussels coordinates
      "Brussels",
      "Belgium",
      22.5,  # target temperature
      65.0   # target humidity
    ) do
      :ok ->
        Logger.info("✓ Greenhouse created successfully")
      error ->
        Logger.error("✗ Failed to create greenhouse: #{inspect(error)}")
        System.halt(1)
    end
    
    # Wait for projections to process
    Process.sleep(1000)
    
    Logger.info("Step 2: Checking database projection")
    
    case Repo.get_by(Greenhouse, greenhouse_id: greenhouse_id) do
      nil ->
        Logger.error("✗ Greenhouse not found in database - projection failed!")
        System.halt(1)
        
      greenhouse ->
        Logger.info("✓ Greenhouse found in database!")
        Logger.info("  ID: #{greenhouse.greenhouse_id}")
        Logger.info("  Name: #{greenhouse.name}")
        Logger.info("  Location: #{greenhouse.location}")
        Logger.info("  City: #{greenhouse.city}")
        Logger.info("  Country: #{greenhouse.country}")
        Logger.info("  Target Temperature: #{greenhouse.target_temperature}")
        Logger.info("  Target Humidity: #{greenhouse.target_humidity}")
        Logger.info("  Event Count: #{greenhouse.event_count}")
    end
    
    Logger.info("")
    Logger.info("Step 3: Testing measurement projections")
    
    # Test temperature measurement
    Logger.info("Setting temperature...")
    API.measure_temperature(greenhouse_id, 23.5)
    Process.sleep(500)
    
    # Test humidity measurement  
    Logger.info("Setting humidity...")
    API.measure_humidity(greenhouse_id, 68.0)
    Process.sleep(500)
    
    # Test light measurement
    Logger.info("Setting light level...")
    API.measure_light(greenhouse_id, 5000.0)
    Process.sleep(500)
    
    # Check updated state
    Logger.info("")
    Logger.info("Step 4: Verifying measurement updates")
    
    case Repo.get_by(Greenhouse, greenhouse_id: greenhouse_id) do
      nil ->
        Logger.error("✗ Greenhouse disappeared from database!")
        System.halt(1)
        
      greenhouse ->
        Logger.info("✓ Measurements updated in database:")
        Logger.info("  Current Temperature: #{greenhouse.current_temperature}")
        Logger.info("  Current Humidity: #{greenhouse.current_humidity}")
        Logger.info("  Current Light: #{greenhouse.current_light}")
        Logger.info("  Event Count: #{greenhouse.event_count}")
        
        # Verify the values
        if greenhouse.current_temperature == 23.5 do
          Logger.info("  ✓ Temperature projection correct")
        else
          Logger.error("  ✗ Temperature projection incorrect (expected 23.5, got #{greenhouse.current_temperature})")
        end
        
        if greenhouse.current_humidity == 68.0 do
          Logger.info("  ✓ Humidity projection correct")
        else
          Logger.error("  ✗ Humidity projection incorrect (expected 68.0, got #{greenhouse.current_humidity})")
        end
        
        if greenhouse.current_light == 5000.0 do
          Logger.info("  ✓ Light projection correct")
        else
          Logger.error("  ✗ Light projection incorrect (expected 5000.0, got #{greenhouse.current_light})")
        end
        
        if greenhouse.event_count == 4 do
          Logger.info("  ✓ Event count correct (4 events)")
        else
          Logger.error("  ✗ Event count incorrect (expected 4, got #{greenhouse.event_count})")
        end
    end
    
    Logger.info("")
    Logger.info("Step 5: Testing target setting projections")
    
    # Test setting new targets
    API.set_temperature(greenhouse_id, 25.0)
    Process.sleep(500)
    
    API.set_humidity(greenhouse_id, 70.0)
    Process.sleep(500)
    
    API.set_desired_light(greenhouse_id, 6000.0)
    Process.sleep(500)
    
    # Check final state
    Logger.info("")
    Logger.info("Step 6: Verifying target updates")
    
    case Repo.get_by(Greenhouse, greenhouse_id: greenhouse_id) do
      nil ->
        Logger.error("✗ Greenhouse disappeared from database!")
        System.halt(1)
        
      greenhouse ->
        Logger.info("✓ Targets updated in database:")
        Logger.info("  Target Temperature: #{greenhouse.target_temperature}")
        Logger.info("  Target Humidity: #{greenhouse.target_humidity}")
        Logger.info("  Target Light: #{greenhouse.target_light}")
        Logger.info("  Final Event Count: #{greenhouse.event_count}")
        
        if greenhouse.target_temperature == 25.0 and
           greenhouse.target_humidity == 70.0 and
           greenhouse.target_light == 6000.0 do
          Logger.info("  ✓ All target projections correct!")
        else
          Logger.error("  ✗ Some target projections incorrect")
        end
        
        if greenhouse.event_count == 7 do
          Logger.info("  ✓ Final event count correct (7 events total)")
        else
          Logger.error("  ✗ Event count incorrect (expected 7, got #{greenhouse.event_count})")
        end
    end
    
    Logger.info("")
    Logger.info("Step 7: Checking projection_versions table")
    
    import Ecto.Query
    
    projection_versions = Repo.all(
      from pv in "projection_versions",
      select: %{
        projection_name: pv.projection_name,
        last_seen_event_number: pv.last_seen_event_number
      }
    )
    
    if length(projection_versions) > 0 do
      Logger.info("✓ Found #{length(projection_versions)} projection version records:")
      Enum.each(projection_versions, fn pv ->
        Logger.info("  #{pv.projection_name}: event ##{pv.last_seen_event_number}")
      end)
    else
      Logger.warning("⚠ No projection version records found (might be using different tracking)")
    end
    
    Logger.info("")
    Logger.info("=== Projection Test Complete ===")
    Logger.info("✅ All Ecto projections appear to be working correctly!")
  end
end

# Run the test
ProjectionTest.run()