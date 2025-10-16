defmodule GreenhouseTycoon.Greenhouses do
  @moduledoc """
  Context for managing greenhouse read models.
  """

  import Ecto.Query
  alias GreenhouseTycoon.Repo
  alias GreenhouseTycoon.Greenhouse
  

  

  @doc """
  Gets a greenhouse by ID.
  """
  @spec get_greenhouse(String.t()) :: {:ok, Greenhouse.t() | nil} | {:error, term()}
  def get_greenhouse(greenhouse_id) do
    case Repo.get(Greenhouse, greenhouse_id) do
      nil -> {:ok, nil}
      greenhouse -> {:ok, greenhouse}
    end
  end

  @doc """
  Gets all greenhouses.
  """
  @spec list_greenhouses() :: [Greenhouse.t()]
  def list_greenhouses do
    Repo.all(Greenhouse)
  end

  @doc """
  Counts the number of greenhouses.
  """
  @spec count_greenhouses() :: integer()
  def count_greenhouses do
    Repo.aggregate(Greenhouse, :count, :greenhouse_id)
  end

  @doc """
  Gets greenhouses by status.
  """
  @spec get_greenhouses_by_status(String.t()) :: [Greenhouse.t()]
  def get_greenhouses_by_status(status) do
    Repo.all(from g in Greenhouse, where: g.status == ^status)
  end

  @doc """
  Calculates average temperature across all active greenhouses.
  """
  @spec average_temperature() :: float()
  def average_temperature do
    query = from g in Greenhouse, where: g.current_temperature > 0, select: avg(g.current_temperature)
    case Repo.one(query) do
      nil -> 0.0
      avg -> Float.round(avg, 1)
    end
  end

  
end
