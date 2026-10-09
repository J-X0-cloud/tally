defmodule TallyWeb.HealthController do
  use TallyWeb, :controller

  @doc """
  Liveness probe for the platform health check.
  """
  def show(conn, _params) do
    json(conn, %{status: "ok", service: "tally-collector"})
  end
end
