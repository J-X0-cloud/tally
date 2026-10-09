defmodule TallyWeb.ErrorJSONTest do
  use ExUnit.Case, async: true

  test "renders 404 in the API error shape" do
    assert TallyWeb.ErrorJSON.render("404.json", %{}) == %{
             error: "not_found",
             message: "Not Found"
           }
  end

  test "renders 500 in the API error shape" do
    assert TallyWeb.ErrorJSON.render("500.json", %{}) ==
             %{error: "internal_server_error", message: "Internal Server Error"}
  end
end
