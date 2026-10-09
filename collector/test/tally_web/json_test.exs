defmodule TallyWeb.JSONTest do
  use ExUnit.Case, async: true

  alias TallyWeb.JSON

  doctest JSON

  test "turns structs and dates into JSON-friendly values" do
    delta = Tally.Stats.Delta.new(110, 100)

    assert JSON.camelize(%{delta: delta, at: ~U[2026-09-25 14:40:00Z], day: ~D[2026-09-25]}) == %{
             "delta" => %{"text" => "10%", "direction" => :up, "good" => true, "change" => 10.0},
             "at" => "2026-09-25T14:40:00Z",
             "day" => "2026-09-25"
           }
  end

  test "leaves camelCase and single-word keys alone" do
    assert JSON.camelize(%{"currentVisitors" => 1, "site" => "x"}) ==
             %{"currentVisitors" => 1, "site" => "x"}
  end
end
