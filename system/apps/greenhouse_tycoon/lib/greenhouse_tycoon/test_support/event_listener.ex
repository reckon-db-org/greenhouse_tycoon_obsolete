defmodule GreenhouseTycoon.TestSupport.EventListener do
  @moduledoc """
  Test support module for capturing and verifying events in tests.
  
  This module helps us verify that events are flowing through the system correctly
  by subscribing to both ExESDB PubSub and Phoenix PubSub channels.
  """
  
  use GenServer
  require Logger

  alias GreenhouseTycoon.InitializeGreenhouse.EventV1, as: GreenhouseInitialized

  defstruct [:pid, :events, :subscriptions]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    # Subscribe to ExESDB events (direct from event store)
    Phoenix.PubSub.subscribe(:ex_esdb_events, "greenhouse_tycoon:$all")
    
    # Subscribe to any Phoenix PubSub channels if the app publishes there
    if Code.ensure_loaded?(GreenhouseTycoon.PubSub) do
      Phoenix.PubSub.subscribe(GreenhouseTycoon.PubSub, "greenhouse_events")
    end
    
    Logger.info("EventListener started, subscribed to events")
    
    {:ok, %__MODULE__{
      pid: self(),
      events: [],
      subscriptions: ["greenhouse_tycoon:$all", "greenhouse_events"]
    }}
  end

  def get_events do
    GenServer.call(__MODULE__, :get_events)
  end

  def clear_events do
    GenServer.call(__MODULE__, :clear_events)
  end

  def wait_for_event(event_type, timeout \\ 5_000) do
    GenServer.call(__MODULE__, {:wait_for_event, event_type, timeout}, timeout + 1_000)
  end

  def handle_call(:get_events, _from, %__MODULE__{events: events} = state) do
    {:reply, Enum.reverse(events), state}
  end

  def handle_call(:clear_events, _from, state) do
    {:reply, :ok, %{state | events: []}}
  end

  def handle_call({:wait_for_event, event_type, timeout}, from, state) do
    # Check if we already have the event
    matching_event = Enum.find(state.events, fn event ->
      matches_event_type?(event, event_type)
    end)

    case matching_event do
      nil ->
        # Set up a timer to wait for the event
        timer_ref = Process.send_after(self(), {:timeout, from, event_type}, timeout)
        new_state = Map.put(state, {:waiting, from}, {event_type, timer_ref})
        {:noreply, new_state}
      
      event ->
        {:reply, {:ok, event}, state}
    end
  end

  def handle_info({:timeout, from, event_type}, state) do
    GenServer.reply(from, {:error, :timeout, event_type})
    new_state = Map.delete(state, {:waiting, from})
    {:noreply, new_state}
  end

  # Handle events from ExESDB PubSub
  def handle_info({:events, events}, state) when is_list(events) do
    Logger.info("EventListener received #{length(events)} events from ExESDB")
    
    new_events = Enum.map(events, fn event ->
      %{
        source: :ex_esdb,
        type: event.event_type,
        data: event.data,
        metadata: event.metadata,
        stream_id: event.event_stream_id,
        event_number: event.event_number,
        timestamp: DateTime.utc_now()
      }
    end)
    
    updated_state = %{state | events: new_events ++ state.events}
    
    # Check if any waiting clients should be notified
    check_waiting_clients(updated_state, new_events)
  end

  # Handle events from Phoenix PubSub
  def handle_info({event_type, event_data}, state) do
    Logger.info("EventListener received event from Phoenix PubSub: #{inspect(event_type)}")
    
    new_event = %{
      source: :phoenix_pubsub,
      type: event_type,
      data: event_data,
      timestamp: DateTime.utc_now()
    }
    
    updated_state = %{state | events: [new_event | state.events]}
    
    # Check if any waiting clients should be notified
    check_waiting_clients(updated_state, [new_event])
  end

  def handle_info(message, state) do
    Logger.debug("EventListener received unexpected message: #{inspect(message)}")
    {:noreply, state}
  end

  defp check_waiting_clients(state, new_events) do
    # Find any clients waiting for these event types
    waiting_clients = 
      state
      |> Map.to_list()
      |> Enum.filter(fn {key, _value} -> match?({:waiting, _}, key) end)

    Enum.each(waiting_clients, fn {{:waiting, from}, {expected_type, timer_ref}} ->
      matching_event = Enum.find(new_events, fn event ->
        matches_event_type?(event, expected_type)
      end)

      if matching_event do
        Process.cancel_timer(timer_ref)
        GenServer.reply(from, {:ok, matching_event})
      end
    end)

    # Remove any clients that were notified
    updated_state = 
      Enum.reduce(waiting_clients, state, fn {{:waiting, from} = key, {expected_type, _timer_ref}}, acc ->
        matching_event = Enum.find(new_events, fn event ->
          matches_event_type?(event, expected_type)
        end)

        if matching_event do
          Map.delete(acc, key)
        else
          acc
        end
      end)

    {:noreply, updated_state}
  end

  defp matches_event_type?(%{type: actual_type}, expected_type) when is_binary(expected_type) do
    actual_type == expected_type
  end

  defp matches_event_type?(%{type: actual_type, data: %GreenhouseInitialized{}}, :greenhouse_initialized) do
    actual_type == "greenhouse_initialized:v1"
  end

  defp matches_event_type?(_event, _expected_type), do: false
end