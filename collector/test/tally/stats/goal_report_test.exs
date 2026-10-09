defmodule Tally.Stats.GoalReportTest do
  use ExUnit.Case, async: true

  import Tally.Factory

  alias Tally.Stats.Goal
  alias Tally.Stats.GoalReport
  alias Tally.Stats.Visit

  test "uniques, totals, conversion rate and revenue per goal" do
    visits =
      Visit.build([
        pageview("/", visitor_id: "a"),
        custom("Purchase", visitor_id: "a", at: 10, revenue: %{amount: 64.0, currency: "USD"}),
        custom("Purchase", visitor_id: "a", at: 20, revenue: %{amount: 36.0, currency: "USD"}),
        pageview("/checkout/thank-you", visitor_id: "a", at: 30),
        pageview("/", visitor_id: "b"),
        pageview("/", visitor_id: "c"),
        custom("Purchase", visitor_id: "c", at: 10, revenue: %{amount: 12.0, currency: "EUR"}),
        pageview("/", visitor_id: "d")
      ])

    goals = [
      Goal.new!(%{type: :event, match: "Purchase"}),
      Goal.new!(%{type: :page, match: "/checkout/*"}),
      Goal.new!(%{type: :event, match: "Newsletter signup"})
    ]

    assert [purchase, thank_you, newsletter] = GoalReport.run(visits, goals)

    assert purchase.uniques == 2
    assert purchase.total == 3
    assert purchase.conversion_rate == 50.0
    assert purchase.revenue == %{currency: "USD", amount: 100.0}

    assert %{name: "Visit /checkout/*", uniques: 1, total: 1, revenue: nil} = thank_you
    assert %{uniques: 0, total: 0, conversion_rate: +0.0} = newsletter
  end

  test "no visits" do
    goals = [Goal.new!(%{type: :event, match: "Purchase"})]
    assert [%{uniques: 0, conversion_rate: +0.0}] = GoalReport.run([], goals)
  end
end
