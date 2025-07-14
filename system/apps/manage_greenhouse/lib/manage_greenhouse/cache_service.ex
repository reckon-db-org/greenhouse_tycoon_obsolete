defmodule ManageGreenhouse.CacheService do
  @moduledoc """
  Service for managing greenhouse read model caches using Cachex.

  This service provides a clean interface for interacting with
  cached greenhouse read models and handles unexpected ExESDB messages.
  """

  use GenServer
  require Logger
  @cache_name :manage_greenhouse_read_models

  @doc """
  Starts the cache service GenServer.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent
    }
  end

  @impl true
  def init(_opts) do
    # Start Cachex cache for greenhouse read models
    case Cachex.start(@cache_name) do
      {:ok, _pid} ->
        {:ok, %{}}

      {:error, {:already_started, _pid}} ->
        {:ok, %{}}

      error ->
        {:stop, error}
    end
  end

  # Handle ExESDB events that bypass the adapter (shouldn't happen but catch them)
  @impl true
  def handle_info({:events, [%ExESDB.Schema.EventRecord{}]}, state) do
    # Silently ignore ExESDB events - they should go through the adapter
    {:noreply, state}
  end

  # Handle any unexpected messages
  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  @doc """
  Gets a greenhouse by ID.
  """
  @spec get_greenhouse(String.t()) :: {:ok, map() | nil} | {:error, term()}
  def get_greenhouse(greenhouse_id) do
    case Cachex.get(@cache_name, greenhouse_id) do
      {:ok, nil} ->
        {:ok, nil}

      {:ok, read_model} ->
        {:ok, read_model}

      {:error, reason} = error ->
        Logger.error("ManageGreenhouse.CacheService: Error retrieving greenhouse #{greenhouse_id}: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Gets all greenhouses.
  """
  @spec list_greenhouses() :: [map()]
  def list_greenhouses do
    case Cachex.keys(@cache_name) do
      {:ok, keys} ->
        keys
        |> Enum.map(fn key ->
          case Cachex.get(@cache_name, key) do
            {:ok, read_model} when not is_nil(read_model) -> read_model
            _ -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.sort_by(& &1.greenhouse_id)

      {:error, reason} ->
        Logger.error("ManageGreenhouse.CacheService: Failed to get cache keys: #{inspect(reason)}")
        []
    end
  end

  @doc """
  Counts the number of greenhouses.
  """
  @spec count_greenhouses() :: integer()
  def count_greenhouses do
    case Cachex.size(@cache_name) do
      {:ok, size} -> size
      {:error, _reason} -> 0
    end
  end

  @doc """
  Gets cache statistics.
  """
  @spec cache_stats() :: map()
  def cache_stats do
    case Cachex.stats(@cache_name) do
      {:ok, stats} -> stats
      {:error, _reason} -> %{}
    end
  end

  @doc """
  Clears all greenhouse data from the cache.
  """
  @spec clear_cache() :: :ok | {:error, term()}
  def clear_cache do
    case Cachex.clear(@cache_name) do
      {:ok, _count} -> :ok
      error -> error
    end
  end
end
