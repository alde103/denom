defmodule Denom.MixProject do
  use Mix.Project

  @app :denom
  @version "0.1.0"
  @all_targets [:rpi, :rpi0, :rpi2, :rpi3, :rpi3a, :rpi4, :bbb, :osd32mp1, :x86_64]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.9",
      archives: [nerves_bootstrap: "~> 1.10"],
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Denom.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:nerves, "~> 1.7.15", runtime: false},
      {:shoehorn, "~> 0.8.0"},
      {:ring_logger, "~> 0.8.3"},
      {:toolshed, "~> 0.2.13"},
      {:opex62541, github: "valiot/opex62541"},
      {:yggdrasil, github: "valiot/yggdrasil"},
      {:modbux, "~> 0.3.8"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.11.6", targets: @all_targets},
      {:nerves_pack, "~> 0.6.0", targets: @all_targets},

      # Dependencies for specific targets
      # NOTE: It's generally low risk and recommended to follow minor version
      # bumps to Nerves systems. Since these include Linux kernel and Erlang
      # version updates, please review their release notes in case
      # changes to your application are needed.
      # Specific target dependencies
      {
        :valiot_system_rpi,
        github: "valiot/valiot_system_rpi",
        tag: "v1.20.0-valiot.12",
        runtime: false,
        targets: :rpi
      },
      #{:nerves_system_rpi0, "~> 1.13", runtime: false, targets: :rpi0},
      {
        :valiot_system_rpi3,
        github: "valiot/valiot_system_rpi3",
        tag: "v1.20.0-valiot.12",
        runtime: false,
        targets: :rpi3
      },
      #{:nerves_system_bbb, "~> 2.8", runtime: false, targets: :bbb}
      {
        :valiot_system_rpi4,
        github: "valiot/valiot_system_rpi4",
        tag: "v1.20.0-valiot.12",
        runtime: false,
        targets: :rpi4
      },
    ]
  end

  def release do
    [
      overwrite: true,
      # Erlang distribution is not started automatically.
      # See https://hexdocs.pm/nerves_pack/readme.html#erlang-distribution
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod or [keep: ["Docs"]]
    ]
  end
end
