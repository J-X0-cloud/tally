defmodule Tally.Stats.TimeseriesTest do
  use ExUnit.Case, async: true

  import Tally.Factory

  alias Tally.Stats.Period
  alias Tally.Stats.Timeseries
  alias Tally.Stats.Visit

  test "one point per bucket, with empty buckets as zeros" do
    {:ok, period} = Period.new("7d", today: ~D[2026-09-25])

    visits =
      Visit.build([
        pageview("/", visitor_id: "a", at: ~U[2026-09-25 09:00:00Z]),
        pageview("/", visitor_id: "b", at: ~U[2026-09-25 11:00:00Z]),
        pageview("/", visitor_id: "a", at: ~U[2026-09-23 12:00:00Z])
      ])

    points = Timeseries.run(visits, period, [])

    assert length(points) == 7
    assert Enum.map(points, & &1.visitors) == [0, 0, 0, 0, 1, 0, 2]
    assert List.last(points).label == "Sep 25"
    assert List.last(points).date == "2026-09-25T00:00:00Z"
  end

  test "hourly buckets for a day" do
    {:ok, period} = Period.new("day", today: ~D[2026-09-25])
    visits = Visit.build([pageview("/", at: ~U[2026-09-25 14:40:00Z])])

    points = Timeseries.run(visits, period, [])
    assert Enum.at(points, 14).visitors == 1
    assert Enum.at(points, 14).label == "14:00"
  end
end
