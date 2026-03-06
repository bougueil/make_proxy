defmodule MakeProxy.MixProject do
  use Mix.Project

  @version "0.3.0"
  @description "HTTP/HTTPS/Socks4/Socks5 proxy in Elixir"
  @source_url "https://github.com/bougueil/make_proxy"

  def project do
    [
      app: :make_proxy,
      version: @version,
      elixir: ">= 1.14.1",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      releases: releases(),
      deps: deps(),
      package: package(),
      description: @description,
      name: "make_proxy"
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

  defp aliases do
    [
      build_release: ["clean", "deps.get", "release"],
      precommit: [
        "compile --warning-as-errors",
        "deps.unlock --unused",
        "format",
        "credo",
        "dialyzer --unmatched_returns"
      ]
    ]
  end

  defp package do
    %{
      licenses: ["BSD-4-Clause license"],
      maintainers: ["bougueil"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "GitHub" => @source_url
      },
      files: ["lib", "mix.exs", "README.md", "CHANGELOG.md", ".formatter.exs"]
    }
  end
end
