defmodule TallyWeb.EventControllerTest do
  use TallyWeb.ConnCase, async: false

  alias Tally.Events.Buffer
  alias Tally.Events.Store

  @ua "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"

  @payload %{
    "n" => "pageview",
    "u" => "https://harrowfield.co/shop/mugs",
    "r" => "https://www.google.com/",
    "w" => 1280,
    "d" => "harrowfield.co"
  }

  setup %{conn: conn} do
    Buffer.flush()
    Store.clear()
    Tally.Live.reset()

    conn =
      conn
      |> put_req_header("user-agent", @ua)
      |> put_req_header("x-forwarded-for", "203.0.113.7")
      |> put_req_header("cf-ipcountry", "US")

    %{conn: conn}
  end

  defp beacon(conn, body, path \\ "/api/event") do
    conn
    |> put_req_header("content-type", "text/plain;charset=UTF-8")
    |> post(path, body)
  end

  defp stored do
    Buffer.flush()
    Store.events("harrowfield.co", ~U[2000-01-01 00:00:00Z], ~U[2100-01-01 00:00:00Z])
  end

  test "accepts a text/plain beacon and stores an anonymous event", %{conn: conn} do
    conn = beacon(conn, Jason.encode!(@payload))

    assert response(conn, 202) == ""
    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]

    assert [event] = stored()
    assert event.path == "/shop/mugs"
    assert event.source == "Google"
    assert event.channel == "Organic Search"
    assert event.country == "US"
    assert event.screen == "Laptop"
    assert event.browser == "Safari"
    assert event.os == "macOS"
    refute Jason.encode!(event) =~ "203.0.113.7"
  end

  test "accepts application/json too", %{conn: conn} do
    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/event", Jason.encode!(@payload))

    assert response(conn, 202)
    assert [_] = stored()
  end

  test "the proxy paths reach the same endpoint", %{conn: conn} do
    assert conn |> beacon(Jason.encode!(@payload), "/event") |> response(202)

    assert build_conn()
           |> put_req_header("user-agent", @ua)
           |> beacon(Jason.encode!(@payload), "/stats/event")
           |> response(202)

    assert length(stored()) == 2
  end

  test "records live activity", %{conn: conn} do
    beacon(conn, Jason.encode!(@payload))
    :sys.get_state(Tally.Live)
    assert Tally.Live.count("harrowfield.co") == 1
  end

  test "drops bots and unknown sites with the same 202", %{conn: conn} do
    bot =
      build_conn()
      |> put_req_header("user-agent", "Mozilla/5.0 (compatible; Googlebot/2.1)")
      |> beacon(Jason.encode!(@payload))

    assert response(bot, 202) == ""

    unknown = beacon(conn, Jason.encode!(%{@payload | "d" => "elsewhere.example"}))
    assert response(unknown, 202) == ""

    assert stored() == []
  end

  test "rejects invalid JSON and invalid payloads with details", %{conn: conn} do
    assert %{"error" => "invalid_json"} = conn |> beacon("{nope") |> json_response(400)

    body = Jason.encode!(%{@payload | "w" => "wide", "u" => "/relative"})

    assert %{"error" => "invalid_payload", "issues" => issues} =
             build_conn()
             |> put_req_header("user-agent", @ua)
             |> beacon(body)
             |> json_response(400)

    assert issues == %{"w" => ["must be an integer"], "u" => ["must be an absolute http(s) URL"]}
  end

  test "rejects oversized bodies", %{conn: conn} do
    body = Jason.encode!(Map.put(@payload, "p", %{"x" => String.duplicate("a", 20_000)}))
    assert %{"error" => "payload_too_large"} = conn |> beacon(body) |> json_response(413)
  end

  test "answers CORS preflight", %{conn: conn} do
    conn = options(conn, "/api/event")
    assert response(conn, 204) == ""
    assert get_resp_header(conn, "access-control-allow-methods") == ["POST, OPTIONS"]
    assert get_resp_header(conn, "access-control-max-age") == ["86400"]
  end

  test "sets no cookies", %{conn: conn} do
    conn = beacon(conn, Jason.encode!(@payload))
    assert get_resp_header(conn, "set-cookie") == []
  end
end
