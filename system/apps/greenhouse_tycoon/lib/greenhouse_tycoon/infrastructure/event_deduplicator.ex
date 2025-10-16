defmodule GreenhouseTycoon.Infrastructure.EventDeduplicator do
  @moduledoc """
  Event deduplication service - NO-OP version.
  
  This is a simplified version that doesn't use caching.
  In production, you might want to use ETS or a proper deduplication strategy.
  """

  use GenServer
  require Logger

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Check if an event has already been processed.
  Always returns false (no deduplication).
  """
  def is_duplicate?(_event_id) do
    false
  end

  @doc """
  Mark an event as processed (no-op).
  """
  def mark_processed(_event_id) do
    :ok
  end

  @doc """
  Process an event with deduplication check.
  Always processes the event (no deduplication).
  """
  def process_with_dedup(_event_id, processor_fun) when is_function(processor_fun, 0) do
    {:ok, processor_fun.()}
  end

  @doc """
  Get current cache statistics.
  Returns empty stats.
  """
  def stats do
    %{}
  end

  @doc """
  Clear all cached event IDs (no-op).
  """
  def clear do
    :ok
  end

  # Server Implementation

  @impl GenServer
  def init(_opts) do
    Logger.info("EventDeduplicator started (no-op version without caching)")
    {:ok, %{}}
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5000
    }
  end
end
