defmodule MakeProxy.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :make_proxy,
      version: @version,
      elixir: ">= 1.14.1",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      releases: releases(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MakeProxy.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:thousand_island, "~> 1.0"},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp releases do
    [
      make_proxy: [
        include_erts: false,
        version: @version,
        include_executables_for: [:unix],
        cookie: "make_proxy"
      ]
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      precommit: [
        "compile --warning-as-errors",
        "deps.unlock --unused",
        "format",
        "credo",
        "dialyzer --unmatched_returns"
      ]
    ]
  end
end
