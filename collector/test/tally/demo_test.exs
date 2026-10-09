defmodule Tally.DemoTest do
  use ExUnit.Case, async: true

  alias Tally.Demo

  test "dashboard/0 has everything the demo page needs" do
    dashboard = Demo.dashboard()

    assert dashboard.site["domain"] == "harrowfield.co"
    assert dashboard.default_range == "30d"
    assert Enum.map(dashboard.ranges, & &1.key) == ["today", "7d", "30d", "12m"]
    assert Enum.map(dashboard.metrics, & &1.key) |> length() == 6

    assert Enum.map(dashboard.dimensions, & &1.key) == [
             "sources",
             "pages",
             "locations",
             "devices"
           ]

    assert Map.keys(dashboard.data) |> Enum.sort() == ["12m", "30d", "7d", "today"]

    tabs = hd(dashboard.dimensions).tabs
    assert %{key: "sources", chip: "source", mono: false} = Enum.at(tabs, 1)
    refute Map.has_key?(hd(tabs), :rows)
  end

  test "dashboard/0 is cached" do
    assert Demo.dashboard() === Demo.dashboard()
  end

  test "range/1 and breakdown/3" do
    assert {:ok, %{key: "7d"}} = Demo.range("7d")
    assert {:error, {:invalid, "range", _}} = Demo.range("1d")

    assert {:ok, [%{name: _} | _]} = Demo.breakdown("devices", "browser", "today")
    assert Demo.breakdown("devices", "nope", "today") == {:error, {:not_found, "tab"}}
    assert Demo.breakdown("nope", "browser", "today") == {:error, {:not_found, "dimension"}}
  end

  test "realtime/0" do
    realtime = Demo.realtime()
    assert realtime.current_visitors == 38
    assert length(realtime.spark) == 30
    assert %{"path" => "/products/speckled-stoneware-mug"} = hd(realtime.feed)
  end
end
