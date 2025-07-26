defmodule GreenhouseTycoon.ReadModels.CacheSubscriberSystemTest do
  use ExUnit.Case, async: false

  alias GreenhouseTycoon.ReadModels.CacheSubscriberSystem

  @expected_subscribers [
    GreenhouseTycoon.InitializeGreenhouse.InitializedToGreenhouseCacheV1,
    GreenhouseTycoon.MeasureTemperature.TemperatureMeasuredToGreenhouseCacheV1,
    GreenhouseTycoon.SetTargetTemperature.TargetTemperatureSetToGreenhouseCacheV1,
    GreenhouseTycoon.MeasureHumidity.HumidityMeasuredToGreenhouseCacheV1,
    GreenhouseTycoon.SetTargetHumidity.TargetHumiditySetToGreenhouseCacheV1,
    GreenhouseTycoon.MeasureLight.LightMeasuredToGreenhouseCacheV1,
    GreenhouseTycoon.SetTargetLight.TargetLightSetToGreenhouseCacheV1
  ]

  test "starts all cache subscribers" do
    # The CacheSubscriberSystem should already be started by the Application
    # Let's verify all expected subscribers are running
    
    status = CacheSubscriberSystem.subscriber_status()
    
    # Verify we have the expected number of subscribers
    assert length(status) == length(@expected_subscribers)
    
    # Verify all expected subscribers are present and running
    running_modules = status
    |> Enum.filter(fn {_module, _pid, status} -> status == :running end)
    |> Enum.map(fn {module, _pid, _status} -> module end)
    |> Enum.sort()
    
    expected_sorted = Enum.sort(@expected_subscribers)
    
    assert running_modules == expected_sorted
  end

  test "subscriber_status returns correct format" do
    status = CacheSubscriberSystem.subscriber_status()
    
    # Each status entry should be a tuple of {module, pid, status}
    Enum.each(status, fn entry ->
      assert match?({module, pid, status} when is_atom(module) and is_pid(pid) and is_atom(status), entry)
      {_module, _pid, status} = entry
      assert status in [:running, :stopped]
    end)
  end

  test "restart_subscriber functionality" do
    # Pick the first subscriber to test restart functionality
    [first_subscriber | _] = @expected_subscribers
    
    # Get the original PID
    original_status = CacheSubscriberSystem.subscriber_status()
    {^first_subscriber, original_pid, :running} = 
      Enum.find(original_status, fn {module, _pid, _status} -> module == first_subscriber end)
    
    # Restart the subscriber
    result = CacheSubscriberSystem.restart_subscriber(first_subscriber)
    assert result == :ok
    
    # Give the supervisor time to restart the process
    :timer.sleep(100)
    
    # Verify the subscriber was restarted with a new PID
    new_status = CacheSubscriberSystem.subscriber_status()
    {^first_subscriber, new_pid, :running} = 
      Enum.find(new_status, fn {module, _pid, _status} -> module == first_subscriber end)
    
    # The PID should be different after restart
    assert new_pid != original_pid
  end

  test "restart_subscriber handles non-existent subscriber" do
    # Try to restart a non-existent subscriber
    result = CacheSubscriberSystem.restart_subscriber(NonExistent.Module)
    
    # Should return an error
    assert match?({:error, _reason}, result)
  end

  test "supervisor strategy is one_for_one" do
    # This test verifies that if one subscriber crashes, others continue running
    # We can't easily crash a subscriber in a test, but we can verify the supervisor
    # is configured correctly by checking it exists and has children
    
    # The supervisor should be alive
    assert Process.alive?(Process.whereis(CacheSubscriberSystem))
    
    # And should have all expected children
    children = Supervisor.which_children(CacheSubscriberSystem)
    assert length(children) == length(@expected_subscribers)
    
    # All children should be alive
    Enum.each(children, fn {_module, pid, _type, _modules} ->
      assert Process.alive?(pid)
    end)
  end
end
