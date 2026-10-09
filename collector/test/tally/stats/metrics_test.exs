defmodule Tally.Stats.MetricsTest do
  use ExUnit.Case, async: true

  import Tally.Factory

  alias Tally.Stats.Goal
  alias Tally.Stats.Metrics
  alias Tally.Stats.Visit

  @purchase Goal.new!(%{type: :event, match: "Purchase"})

  defp visits do
    Visit.build([
      # visitor a: two visits, the second converts
      pageview("/", visitor_id: "a", at: 0),
      pageview("/shop", visitor_id: "a", at: 100),
      pageview("/", visitor_id: "a", at: 4000),
      custom("Purchase", visitor_id: "a", at: 4060, revenue: %{amount: 64.0, currency: "USD"}),
      # visitor b: one bounce
      pageview("/journal", visitor_id: "b", at: 200),
      # visitor c: two pages
      pageview("/", visitor_id: "c", at: 300),
      pageview("/about", visitor_id: "c", at: 360),
      custom("Purchase", visitor_id: "c", at: 400, revenue: %{amount: 36.0, currency: "USD"}),
      custom("Purchase", visitor_id: "c", at: 420, revenue: %{amount: 20.0, currency: "CAD"})
    ])
  end

  test "totals/2" do
    totals = Metrics.totals(visits(), [@purchase])

    assert totals.visitors == 3
    assert totals.visits == 4
    assert totals.pageviews == 6
    # only b's visit bounced
    assert totals.bounce == 25.0
    # durations: 100, 60, 0, 120
    assert totals.duration == 70.0
    assert totals.conversions == 2
    assert_in_delta Metrics.conversion_rate(totals), 66.67, 0.01
  end

  test "totals of nothing are zeros" do
    assert Metrics.totals([], [@purchase]) ==
             %{visitors: 0, visits: 0, pageviews: 0, bounce: 0.0, duration: 0.0, conversions: 0}

    assert Metrics.conversion_rate(%{conversions: 0, visitors: 0}) == 0.0
  end

  test "without goals there are no conversions" do
    assert Metrics.totals(visits()).conversions == 0
  end

  test "revenue/1 sums per currency, largest first" do
    assert Metrics.revenue(visits()) == [
             %{currency: "USD", amount: 100.0},
             %{currency: "CAD", amount: 20.0}
           ]
  end

  test "definitions and keys" do
    assert Metrics.keys() == [:visitors, :visits, :pageviews, :bounce, :duration, :conversions]
    assert Metrics.lower_is_better?(:bounce)
    refute Metrics.lower_is_better?(:visitors)
    assert Metrics.parse_key("duration") == {:ok, :duration}
    assert Metrics.parse_key("revenue") == :error
  end
end
