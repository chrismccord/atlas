defmodule Atlas.Mixfile do
  use Mix.Project

  def project do
    [
      app: :atlas,
      version: "0.2.0",
      elixir: ">= 0.13.3",
      deps: deps,
      package: [
        contributors: ["Chris McCord", "Sonny Scroggin"],
        licenses: ["MIT"],
        links: [github: "https://github.com/chrismccord/atlas"]
      ],
      description: """
      Object Relational Mapper for Elixir
      """
    ]
  end

  # Configuration for the OTP application
  def application do
    [
      mod: { Atlas, []},
      registered: []
    ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [{:epgsql, github: "wg/epgsql"}]
  end
end
