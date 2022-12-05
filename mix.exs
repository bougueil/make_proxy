defmodule MakeProxy.MixProject do
  use Mix.Project

  def project do
    [
      app: :make_proxy,
      version: "0.1.0",
      elixir: "~> 1.14.1",
      start_permanent: Mix.env() == :prod,
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
      {:ranch, "~> 2.1.0"},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  defp releases do
    [
      make_proxy: [
        include_erts: false,
        version: "0.1.0",
        include_executables_for: [:unix],
        cookie: "make_proxy"
      ]
    ]
  end
end
