defmodule APISex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :apisex,
      version: "0.1.0",
      elixir: "~> 1.5",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 1.0.0"},
      {:plug, "~> 1.0"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
