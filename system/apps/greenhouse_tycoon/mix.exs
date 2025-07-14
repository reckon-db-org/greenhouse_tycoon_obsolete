defmodule GreenhouseTycoon.MixProject do
  @moduledoc false
  use Mix.Project

  @version "0.1.0"
  @elixir_version "~> 1.17"

  def project do
    [
      app: :greenhouse_tycoon,
      version: @version,
      build_path: "../../_build",
      config_path: "config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: @elixir_version,
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {GreenhouseTycoon.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:dns_cluster, "~> 0.1.1"},
      {:phoenix_pubsub, "~> 2.1"},
      {:jason, "~> 1.2"},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:cachex, "~> 3.6"},
      # APIs app for countries and external services
      {:apis, in_umbrella: true},
      # Ensure ex_esdb_gater compiles first as it contains schemas
      # Then ex_esdb which may depend on gater schemas
      {:ex_esdb, "~> 0.1.4"},
      # Finally ex_esdb_commanded which depends on both
      {:ex_esdb_commanded, "0.1.3"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    []
  end
end
