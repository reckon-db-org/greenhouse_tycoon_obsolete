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
      config_path: "../../config/config.exs",
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
      extra_applications: [
        :logger,
        :runtime_tools,
        :commanded,
        :ex_esdb_commanded,
        :khepri,
        :ra,
        :seshat
      ]
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
      {:ex_esdb, "~> 0.4.6"},
      {:ex_esdb_commanded, "0.2.4"},
      {:commanded_ecto_projections, "~> 1.4"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    []
  end
end
