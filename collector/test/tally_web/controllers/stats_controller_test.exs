defmodule TallyWeb.StatsControllerTest do
  use TallyWeb.ConnCase, async: false

  import Tally.Factory

  alias Tally.Billing.RateLimiter
  alias Tally.Events.Store

  setup do
    Store.clear()
    RateLimiter.reset()
    on_exit(&Store.clear/0)

    Store.insert_all([
      pageview("/", visitor_id: "a", at: ~U[2026-09-24 10:00:00Z]),
      pageview("/products/mug", visitor_id: "a", at: ~U[2026-09-24 10:01:00Z]),
      custom("Add to cart",
        visitor_id: "a",
        at: ~U[2026-09-24 10:02:00Z],
        props: %{"color" => "ash"}
      ),
      custom("Begin checkout", visitor_id: "a", at: ~U[2026-09-24 10:03:00Z]),
      custom("Purchase",
        visitor_id: "a",
        at: ~U[2026-09-24 10:04:00Z],
        revenue: %{amount: 64.0, currency: "USD"}
      ),
      pageview("/journal",
        visitor_id: "b",
        source: "Instagram",
        channel: "Organic Social",
        screen: "Desktop",
        at: ~U[2026-09-25 09:00:00Z]
      )
    ])

    :ok
  end

  defp api(key),
    do: build_conn() |> put_req_header("authorization", "Bearer " <> key)

  defp get_json(path, key \\ "test-business", status \\ 200) do
    api(key) |> get(path) |> json_response(status)
  end

  @base "/api/v1/stats/harrowfield.co"
  @week "period=7d&date=2026-09-25"

  test "requires a valid key" do
    conn = get(build_conn(), "#{@base}/aggregate")
    assert %{"error" => "unauthorized"} = json_response(conn, 401)
    assert get_resp_header(conn, "www-authenticate") == [~s(Bearer realm="tally")]

    assert %{"error" => "unauthorized"} = get_json("#{@base}/aggregate", "wrong", 401)
  end

  test "aggregate" do
    body = get_json("#{@base}/aggregate?#{@week}")

    assert body["site"] == "harrowfield.co"

    assert body["period"] == %{
             "key" => "7d",
             "from" => "2026-09-19T00:00:00Z",
             "to" => "2026-09-26T00:00:00Z",
             "interval" => "day"
           }

    assert body["totals"]["visitors"] == 2
    assert body["totals"]["conversions"] == 1
    assert body["previous"]["visitors"] == 0
    assert body["conversionRate"] == 50.0
    assert body["revenue"] == [%{"currency" => "USD", "amount" => 64.0}]
    # no traffic in the previous week, so there is no change to report
    assert %{"text" => "0.0%", "good" => false} = body["deltas"]["pageviews"]
  end

  test "filters, and their validation" do
    body = get_json("#{@base}/aggregate?#{@week}&filters=source%3D%3DInstagram")
    assert body["totals"]["visitors"] == 1

    assert [%{"dimension" => "source", "operator" => "is", "values" => ["Instagram"]}] =
             body["filters"]

    assert %{"error" => "invalid_parameter", "message" => "filters: " <> _} =
             get_json("#{@base}/aggregate?filters=ip%3D%3D1", "test-business", 400)
  end

  test "timeseries" do
    body = get_json("#{@base}/timeseries?#{@week}")
    assert length(body["points"]) == 7
    assert List.last(body["points"])["label"] == "Sep 25"
    assert Enum.map(body["points"], & &1["visitors"]) == [0, 0, 0, 0, 0, 1, 1]
  end

  test "breakdown" do
    body = get_json("#{@base}/breakdown?#{@week}&property=source")

    assert [%{"name" => "Google", "visitors" => 1, "share" => 50.0}, %{"name" => "Instagram"}] =
             body["rows"]

    assert %{"rows" => [%{"name" => "ash"}]} =
             get_json("#{@base}/breakdown?#{@week}&property=prop:color")

    assert %{"error" => "bad_request", "message" => "property is required"} =
             get_json("#{@base}/breakdown?#{@week}", "test-business", 400)

    assert %{"error" => "invalid_parameter"} =
             get_json("#{@base}/breakdown?#{@week}&property=ip", "test-business", 400)

    assert %{"error" => "bad_request", "message" => "limit must be an integer between 1 and 100"} =
             get_json("#{@base}/breakdown?#{@week}&property=page&limit=500", "test-business", 400)
  end

  test "custom property breakdowns need the Business plan" do
    assert %{
             "error" => "plan_required",
             "message" => "Custom properties needs the Business plan or higher"
           } =
             get_json("#{@base}/breakdown?#{@week}&property=prop:color", "test-growth", 402)
  end

  test "goals" do
    body = get_json("#{@base}/goals?#{@week}")
    purchase = Enum.find(body["goals"], &(&1["name"] == "Purchase"))
    assert purchase["uniques"] == 1
    assert purchase["conversionRate"] == 50.0
    assert purchase["revenue"] == %{"currency" => "USD", "amount" => 64.0}
  end

  test "funnel by name, by steps, and the default" do
    named = get_json("#{@base}/funnel?#{@week}&name=checkout", "test-growth")
    assert named["funnel"]["name"] == "Checkout"
    assert Enum.map(named["funnel"]["steps"], & &1["visitors"]) == [1, 1, 1, 1]

    adhoc = get_json("#{@base}/funnel?#{@week}&steps=page:/journal|event:Purchase")
    assert Enum.map(adhoc["funnel"]["steps"], & &1["visitors"]) == [1, 0]

    assert %{"funnel" => %{"name" => "Checkout"}} = get_json("#{@base}/funnel?#{@week}")

    assert %{"error" => "not_found", "message" => "Unknown funnel"} =
             get_json("#{@base}/funnel?#{@week}&name=nope", "test-business", 404)

    assert %{"error" => "invalid_parameter", "message" => "steps: " <> _} =
             get_json("#{@base}/funnel?#{@week}&steps=page:/only", "test-business", 400)
  end

  test "realtime" do
    assert %{"site" => "harrowfield.co", "visitors" => _} = get_json("#{@base}/realtime")
  end

  test "unknown sites are 404" do
    assert %{"error" => "not_found", "message" => "Unknown site"} =
             get_json("/api/v1/stats/nope.example/aggregate", "test-business", 404)
  end

  test "rate limit headers and 429 after the plan's allowance" do
    conn = api("test-growth") |> get("#{@base}/realtime")
    assert get_resp_header(conn, "x-ratelimit-limit") == ["600"]
    assert get_resp_header(conn, "x-ratelimit-remaining") == ["599"]

    for _ <- 1..599, do: api("test-growth") |> get("#{@base}/realtime")

    conn = api("test-growth") |> get("#{@base}/realtime")
    assert %{"error" => "rate_limited"} = json_response(conn, 429)
    assert [retry] = get_resp_header(conn, "retry-after")
    assert String.to_integer(retry) > 0

    # another key has its own allowance
    assert api("test-business") |> get("#{@base}/realtime") |> json_response(200)
  end

  test "plans without API access get 402" do
    Application.put_env(:tally, :api_keys, %{
      "test-starter" => "starter",
      "test-growth" => "growth"
    })

    on_exit(fn ->
      Application.put_env(:tally, :api_keys, %{
        "test-growth" => "growth",
        "test-business" => "business"
      })
    end)

    assert %{
             "error" => "plan_required",
             "message" => "The Stats API needs the Growth plan or higher"
           } =
             get_json("#{@base}/aggregate", "test-starter", 402)
  end
end
