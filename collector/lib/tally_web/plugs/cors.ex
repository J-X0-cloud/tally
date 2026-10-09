defmodule TallyWeb.Plugs.CORS do
  @moduledoc """
  CORS headers for the ingest endpoint, which every tracked site calls from the browser. Preflight
  requests are answered here with 204.
  """
  @behaviour Plug

  import Plug.Conn

  @headers [
    {"access-control-allow-origin", "*"},
    {"access-control-allow-methods", "POST, OPTIONS"},
    {"access-control-allow-headers", "content-type"},
    {"access-control-max-age", "86400"}
  ]

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%Plug.Conn{method: "OPTIONS"} = conn, _opts) do
    conn
    |> merge_resp_headers(@headers)
    |> send_resp(204, "")
    |> halt()
  end

  def call(conn, _opts), do: merge_resp_headers(conn, @headers)
end
