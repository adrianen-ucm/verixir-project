defmodule Smt.MixProject do
  use Mix.Project

  def project do
    [
      app: :smt_lib,
      version: "0.1.0",
      elixir: "~> 1.13",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      deps: deps()
    ]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 1.0"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end
end
