defmodule TallyWeb.Endpoint do
  @moduledoc """
  HTTP entry point for the collector.

  The service is deliberately cookie-free: there is no session plug and no CSRF token, because nothing
  about a visitor is ever stored on their device. The tracking script posts `text/plain` beacons, so
  the body is read raw by the ingest controller rather than by `Plug.Parsers`.
  """
  use Phoenix.Endpoint, otp_app: :tally

  plug Plug.Static,
    at: "/",
    from: :tally,
    gzip: not code_reloading?,
    only: TallyWeb.static_paths()

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.Head
  plug TallyWeb.Router
end
