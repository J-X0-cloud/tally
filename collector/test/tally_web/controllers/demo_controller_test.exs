defmodule TallyWeb.DemoControllerTest do
  use TallyWeb.ConnCase, async: true

  test "GET /api/demo returns the whole dashboard in camelCase", %{conn: conn} do
    conn = get(conn, "/api/demo")
    body = json_response(conn, 200)

    assert get_resp_header(conn, "cache-control") == [
             "public, max-age=300, stale-while-revalidate=3600"
           ]

    assert body["site"]["name"] == "Harrowfield Supply"
    assert body["defaultRange"] == "30d"
    assert body["defaultMetric"] == "visitors"

    assert hd(body["metrics"]) == %{
             "key" => "visitors",
             "label" => "Unique visitors",
             "format" => "number",
             "lowerIsBetter" => false
           }

    assert Enum.map(body["ranges"], & &1["label"]) == ["Today", "7D", "30D", "12M"]
    assert body["realtime"]["currentVisitors"] == 38

    month = body["data"]["30d"]
    assert month["span"] == "Aug 26 – Sep 24, 2026"
    assert length(month["current"]) == 30
    assert %{"visitors" => _, "bounce" => _} = month["priorTotals"]
    assert %{"text" => "12%", "direction" => "up", "good" => true} = month["deltas"]["visitors"]
    assert is_float(month["conversionRate"])

    assert %{"name" => "Organic Search", "width" => 100.0} =
             hd(month["breakdowns"]["sources"]["channels"])

    assert %{"name" => "Purchase", "conversionRate" => _, "revenue" => _} = hd(month["goals"])
    assert %{"ofFirst" => 100.0, "dropOff" => nil} = hd(month["funnel"])

    today = body["data"]["today"]
    assert List.last(today["current"]) == nil
  end

  test "GET /api/demo/ranges/:range", %{conn: conn} do
    assert %{"key" => "7d", "interval" => "Daily"} =
             conn |> get("/api/demo/ranges/7d") |> json_response(200)

    assert %{"error" => "invalid_parameter", "message" => "range: " <> _} =
             build_conn() |> get("/api/demo/ranges/90d") |> json_response(400)
  end

  test "GET /api/demo/breakdown", %{conn: conn} do
    body =
      conn
      |> get("/api/demo/breakdown?dimension=locations&tab=countries&range=7d")
      |> json_response(200)

    assert %{"name" => "United States", "code" => "US"} = hd(body["rows"])

    assert %{"error" => "bad_request", "message" => "tab is required"} =
             build_conn() |> get("/api/demo/breakdown?dimension=locations") |> json_response(400)

    assert %{"error" => "not_found", "message" => "Unknown tab"} =
             build_conn()
             |> get("/api/demo/breakdown?dimension=locations&tab=planets")
             |> json_response(404)
  end

  test "GET /api/demo/realtime", %{conn: conn} do
    assert %{"currentVisitors" => 38, "spark" => spark, "feed" => [first | _]} =
             conn |> get("/api/demo/realtime") |> json_response(200)

    assert length(spark) == 30
    assert first["ago"] == "2s"
  end
end
