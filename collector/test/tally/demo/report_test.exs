defmodule Tally.Demo.ReportTest do
  use ExUnit.Case, async: true

  alias Tally.Demo.Report
  alias Tally.Demo.Simulation

  setup_all do
    sim = Simulation.run()
    %{sim: sim, ranges: Map.new(Report.range_keys(), &{&1, Report.range(sim, &1)})}
  end

  test "bucket counts per range", %{ranges: ranges} do
    assert length(ranges["today"].current) == 24
    assert Enum.count(ranges["today"].current, &is_nil/1) == 9
    assert length(ranges["7d"].current) == 7
    assert length(ranges["30d"].current) == 30
    assert length(ranges["12m"].current) == 52
    assert length(ranges["12m"].previous) == 52
  end

  test "labels, spans and comparisons", %{ranges: ranges} do
    assert Enum.take(ranges["today"].labels, 3) == ["12am", "1am", "2am"]
    assert Enum.at(ranges["today"].labels, 12) == "12pm"
    assert ranges["today"].span == "Today, Sep 25 · until 2:40pm"
    assert hd(ranges["7d"].labels) == "Fri 18"
    assert hd(ranges["7d"].tips) == "Fri, Sep 18"
    assert ranges["30d"].span == "Aug 26 – Sep 24, 2026"
    assert ranges["12m"].span == "Sep 26, 2025 – Sep 24, 2026"
    assert hd(ranges["12m"].tips) == "Week of Sep 26, 2025"
    assert ranges["12m"].comparison == "vs. previous year"
    assert ranges["7d"].interval == "Daily"
  end

  test "aggregate/2 weights bounce and duration by visits" do
    points = [
      %{visitors: 10, visits: 10, pageviews: 30, bounce: 40, duration: 100, conversions: 1},
      %{visitors: 30, visits: 30, pageviews: 60, bounce: 20, duration: 200, conversions: 2}
    ]

    single = Report.aggregate(points, false)
    assert single.visitors == 40
    assert single.bounce == 25.0
    assert single.duration == 175.0
    assert Report.aggregate(points).visitors == 40 * 0.86
  end

  test "conversion rate and deltas are attached", %{ranges: ranges} do
    range = ranges["30d"]

    assert_in_delta range.conversion_rate,
                    range.totals.conversions / range.totals.visitors * 100,
                    1.0e-9

    assert %Tally.Stats.Delta{text: "12%", direction: :up, good: true} = range.deltas.visitors
  end

  test "breakdown rows are sorted with widths relative to the top row", %{ranges: ranges} do
    rows = Report.breakdown(ranges["30d"], "locations", "countries", "30d")
    assert hd(rows).name == "United States"
    assert hd(rows).code == "US"
    assert hd(rows).width == 100.0
    assert rows == Enum.sort_by(rows, & &1.value, :desc)
    assert Enum.all?(rows, &(&1.width <= 100))
  end

  test "breakdowns vary by range but are stable per range", %{ranges: ranges} do
    a = Report.breakdown(ranges["7d"], "sources", "sources", "7d")
    b = Report.breakdown(ranges["7d"], "sources", "sources", "7d")
    c = Report.breakdown(ranges["30d"], "sources", "sources", "30d")
    assert a == b
    refute Enum.map(a, & &1.share) == Enum.map(c, & &1.share)
  end

  test "goals carry revenue only for purchases", %{ranges: ranges} do
    [purchase | rest] = Report.goals(ranges["30d"], "30d")
    assert purchase.name == "Purchase"
    assert_in_delta purchase.revenue, purchase.uniques * 1.05 * 64.2, 1.0e-6
    assert Enum.all?(rest, &is_nil(&1.revenue))
  end

  test "the funnel narrows step by step", %{ranges: ranges} do
    steps = Report.funnel(ranges["30d"])

    assert Enum.map(steps, & &1.name) == [
             "Viewed a product",
             "Added to cart",
             "Began checkout",
             "Purchased"
           ]

    assert hd(steps).of_first == 100.0
    assert hd(steps).drop_off == nil

    assert steps
           |> Enum.map(& &1.value)
           |> Enum.chunk_every(2, 1, :discard)
           |> Enum.all?(fn [a, b] -> b < a end)
  end

  test "hour_label/1" do
    assert Enum.map([0, 11, 12, 13, 23], &Report.hour_label/1) == [
             "12am",
             "11am",
             "12pm",
             "1pm",
             "11pm"
           ]
  end

  test "validate_range/1" do
    assert Report.validate_range("12m") == {:ok, "12m"}
    assert {:error, {:invalid, "range", _}} = Report.validate_range("90d")
  end
end
