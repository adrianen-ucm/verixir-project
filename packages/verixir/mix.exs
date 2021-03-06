defmodule Verixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :verixir,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.13",
      deps: deps()
    ]
  end

  defp deps do
    [
      {:smt_lib, in_umbrella: true},
      {:boogiex, in_umbrella: true},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false}
    ]
  end
end
