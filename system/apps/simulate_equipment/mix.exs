defmodule SimulateEquipment.MixProject do
  use Mix.Project

  def project do
    [
      app: :simulate_equipment,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  def application do
    [
      mod: {SimulateEquipment.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  defp deps do
    [
      {:phoenix_pubsub, "~> 2.1"},
      {:jason, "~> 1.2"},
      # For event integration with other apps
      {:control_equipment, in_umbrella: true},
      {:maintain_equipment, in_umbrella: true},
      {:manage_greenhouse, in_umbrella: true}
    ]
  end
end
