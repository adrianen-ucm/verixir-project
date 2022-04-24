defmodule SmtLib.MixProject do
  use Mix.Project

  def project do
    [
      app: :smt_lib,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.13",
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 1.0"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "README.md": [title: "Readme"]
      ]
    ]
  end
end
