defmodule ControlEquipment.MixProject do
  use Mix.Project

  def project do
    [
      app: :control_equipment,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  def application do
    [
      mod: {ControlEquipment.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies your project dependencies.
  defp deps do
    [
      {:dns_cluster, "~> 0.1.1"},
      {:phoenix_pubsub, "~> 2.1"},
      {:jason, "~> 1.2"},
      {:finch, "~> 0.13"},
      {:cachex, "~> 3.6"},
      # For simulator integration
      {:ex_esdb, "~> 0.1.4"}
    ]
  end
end
