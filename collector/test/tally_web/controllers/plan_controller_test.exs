defmodule TallyWeb.PlanControllerTest do
  use TallyWeb.ConnCase, async: true

  test "GET /api/plans", %{conn: conn} do
    body = conn |> get("/api/plans") |> json_response(200)

    assert body["volumes"] |> hd() == "10k"
    assert body["yearlyMonthsCharged"] == 10
    assert [starter, growth, business] = body["plans"]
    assert starter["name"] == "Starter"
    assert growth["popular"]
    refute business["popular"]

    assert %{
             "volume" => "100k",
             "monthly" => %{"price" => "$29"},
             "yearly" => %{"price" => "$24.17"}
           } =
             Enum.at(growth["prices"], 1)

    assert %{"feature" => "Stats API", "values" => [false, "600 req/hr", "2,000 req/hr"]} =
             Enum.find(body["comparison"], &(&1["feature"] == "Stats API"))
  end

  test "GET /api/plans/quote", %{conn: conn} do
    assert %{"price" => "$65.83", "note" => "$790 billed yearly · 200k pageviews"} =
             conn
             |> get("/api/plans/quote?plan=business&volume=200k&billing=yearly")
             |> json_response(200)

    assert %{"price" => "$14"} =
             build_conn() |> get("/api/plans/quote?plan=growth&volume=10k") |> json_response(200)

    assert %{"error" => "bad_request"} =
             build_conn()
             |> get("/api/plans/quote?plan=growth&volume=10k&billing=weekly")
             |> json_response(400)

    assert %{"error" => "not_found"} =
             build_conn()
             |> get("/api/plans/quote?plan=platinum&volume=10k")
             |> json_response(404)
  end
end
