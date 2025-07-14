defmodule SimulateCrops.CropGrowthEngine do
  @moduledoc """
  Engine for calculating crop growth based on environmental conditions.
  """

  @doc """
  Calculates crop growth based on current crop state and environmental conditions.
  """
  def calculate_growth(crop_state, environmental_conditions) do
    # Simple growth calculation based on environmental factors
    growth_rate = calculate_growth_rate(environmental_conditions)
    
    new_progress = min(100.0, crop_state.growth_progress + growth_rate)
    
    # Determine growth stage based on progress
    new_stage = determine_growth_stage(new_progress)
    
    # Update crop state
    %{crop_state |
      growth_progress: new_progress,
      growth_stage: new_stage,
      last_growth_update: DateTime.utc_now()
    }
  end

  @doc """
  Applies environmental effects to crop health and condition.
  """
  def apply_environmental_effects(crop_state, environmental_conditions) do
    # Simple environmental effects calculation
    health_factor = calculate_health_factor(environmental_conditions)
    
    # Adjust health based on environmental conditions
    new_health = case crop_state.health_status do
      :healthy -> if health_factor > 0.8, do: :healthy, else: :stressed
      :stressed -> if health_factor > 0.6, do: :healthy, else: :unhealthy
      :unhealthy -> if health_factor > 0.9, do: :stressed, else: :unhealthy
      _ -> :stressed
    end
    
    %{crop_state |
      health_status: new_health,
      environmental_factors: environmental_conditions
    }
  end

  @doc """
  Determines if a crop is ready for harvest.
  """
  def ready_for_harvest?(crop_state) do
    crop_state.growth_progress >= 90.0 and crop_state.growth_stage == :mature
  end

  @doc """
  Estimates yield based on crop state.
  """
  def estimate_yield(crop_state) do
    base_yield = 1.0
    
    # Adjust based on health and growth progress
    health_multiplier = case crop_state.health_status do
      :healthy -> 1.0
      :stressed -> 0.8
      :unhealthy -> 0.5
      _ -> 0.6
    end
    
    progress_multiplier = crop_state.growth_progress / 100.0
    
    base_yield * health_multiplier * progress_multiplier
  end

  # Private helper functions

  defp calculate_growth_rate(environmental_conditions) do
    temp_factor = temperature_factor(environmental_conditions[:temperature] || 20.0)
    humidity_factor = humidity_factor(environmental_conditions[:humidity] || 65.0)
    light_factor = light_factor(environmental_conditions[:light] || 600.0)
    
    base_rate = 2.0  # Base growth rate per tick
    base_rate * temp_factor * humidity_factor * light_factor
  end

  defp calculate_health_factor(environmental_conditions) do
    temp_factor = temperature_factor(environmental_conditions[:temperature] || 20.0)
    humidity_factor = humidity_factor(environmental_conditions[:humidity] || 65.0)
    light_factor = light_factor(environmental_conditions[:light] || 600.0)
    
    (temp_factor + humidity_factor + light_factor) / 3.0
  end

  defp temperature_factor(temp) when temp >= 18 and temp <= 25, do: 1.0
  defp temperature_factor(temp) when temp >= 15 and temp <= 30, do: 0.8
  defp temperature_factor(_), do: 0.5

  defp humidity_factor(humidity) when humidity >= 60 and humidity <= 80, do: 1.0
  defp humidity_factor(humidity) when humidity >= 45 and humidity <= 90, do: 0.8
  defp humidity_factor(_), do: 0.5

  defp light_factor(light) when light >= 500 and light <= 800, do: 1.0
  defp light_factor(light) when light >= 300 and light <= 1000, do: 0.8
  defp light_factor(_), do: 0.5

  defp determine_growth_stage(progress) when progress < 10, do: :germination
  defp determine_growth_stage(progress) when progress < 30, do: :seedling
  defp determine_growth_stage(progress) when progress < 60, do: :vegetative
  defp determine_growth_stage(progress) when progress < 90, do: :flowering
  defp determine_growth_stage(_), do: :mature
end
