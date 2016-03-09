defmodule CBMQWriter.Mixfile do
  use Mix.Project

  def project do
    [app: :cbmqwriter,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:sasl, :logger, :yamerl, :cbserverapi2, :recon],
     mod: {CBMQWriter, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:yamerl, git: "https://github.com/yakaz/yamerl"},
      {:cbserverapi2, git: "https://github.com/redvers/cbserverapi2.git"},
      {:eep, git: "https://github.com/virtan/eep.git"},
      {:exrm, "~> 1.0"},
      {:recon, "~> 2.2"}
    ]
  end
end
