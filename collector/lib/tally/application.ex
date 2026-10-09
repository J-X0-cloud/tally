defmodule Tally.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TallyWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:tally, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Tally.PubSub},
      Tally.Ingest.Salts,
      TallyWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Tally.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TallyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
