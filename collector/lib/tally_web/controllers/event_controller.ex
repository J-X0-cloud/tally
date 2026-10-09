defmodule TallyWeb.EventController do
  @moduledoc """
  `POST /api/event`: ingest one page view or custom event from the tracking script.

  The script sends `text/plain` (a CORS "simple" request, so no preflight), which is read raw
  here; `application/json` bodies already parsed by `Plug.Parsers` are accepted too. Bots and
  sites this deployment doesn't serve get the same `202` as accepted events, so the script never
  retries and configuration never leaks.
  """
  use TallyWeb, :controller

  alias Tally.Ingest
  alias Tally.Ingest.Payload

  def create(conn, _params) do
    with {:ok, payload, conn} <- payload(conn),
         {:ok, event} <- Ingest.from_payload(payload, request(conn)) do
      :ok = Tally.Events.record(event)
      accepted(conn)
    else
      {:drop, _reason} ->
        accepted(conn)

      {:error, :invalid_json} ->
        conn |> put_status(400) |> json(%{error: "invalid_json"})

      {:error, {:invalid, issues}} ->
        conn |> put_status(400) |> json(%{error: "invalid_payload", issues: issues})

      {:error, :too_large} ->
        conn |> put_status(413) |> json(%{error: "payload_too_large"})
    end
  end

  defp payload(%Plug.Conn{body_params: %Plug.Conn.Unfetched{}} = conn), do: read_payload(conn)

  defp payload(%Plug.Conn{body_params: params} = conn) when map_size(params) > 0 do
    with {:ok, payload} <- Payload.validate(params), do: {:ok, payload, conn}
  end

  defp payload(conn), do: read_payload(conn)

  defp read_payload(conn) do
    case read_body(conn, length: Payload.max_body_bytes()) do
      {:ok, body, conn} ->
        with {:ok, payload} <- Payload.parse(body), do: {:ok, payload, conn}

      {:more, _partial, _conn} ->
        {:error, :too_large}

      {:error, _reason} ->
        {:error, :invalid_json}
    end
  end

  defp request(conn) do
    %{headers: conn.req_headers, remote_ip: conn.remote_ip, received_at: DateTime.utc_now()}
  end

  defp accepted(conn), do: send_resp(conn, 202, "")
end
