defmodule FirstPhoenixStackAssembly.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FirstPhoenixStackAssemblyWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:first_phoenix_stack_assembly, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: FirstPhoenixStackAssembly.PubSub},
      # Start a worker by calling: FirstPhoenixStackAssembly.Worker.start_link(arg)
      # {FirstPhoenixStackAssembly.Worker, arg},
      # Start to serve requests, typically the last entry
      FirstPhoenixStackAssemblyWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FirstPhoenixStackAssembly.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FirstPhoenixStackAssemblyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
