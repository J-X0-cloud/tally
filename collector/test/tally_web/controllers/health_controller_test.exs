defmodule TallyWeb.HealthControllerTest do
  use TallyWeb.ConnCase, async: true

  test "GET /api/health", %{conn: conn} do
    assert %{"status" => "ok"} = conn |> get("/api/health") |> json_response(200)
  end

  test "unknown routes answer with a JSON 404", %{conn: conn} do
    assert %{"error" => "not_found"} = conn |> get("/api/nope") |> json_response(404)
  end
end
