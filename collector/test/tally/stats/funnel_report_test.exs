defmodule Tally.Stats.FunnelReportTest do
  use ExUnit.Case, async: true

  import Tally.Factory

  alias Tally.Stats.Funnel
  alias Tally.Stats.FunnelReport
  alias Tally.Stats.Visit

  setup do
    {:ok, funnel} = Funnel.parse("page:/products/*|event:Add to cart|event:Purchase", "Checkout")
    %{funnel: funnel}
  end

  test "counts visitors reaching each step in order", %{funnel: funnel} do
    visits =
      Visit.build([
        # a completes the funnel
        pageview("/products/mug", visitor_id: "a"),
        custom("Add to cart", visitor_id: "a", at: 10),
        custom("Purchase", visitor_id: "a", at: 20),
        # b adds to cart but leaves
        pageview("/products/bowl", visitor_id: "b"),
        custom("Add to cart", visitor_id: "b", at: 10),
        # c views a product only
        pageview("/products/vase", visitor_id: "c"),
        # d buys without viewing a product first in this visit: does not count past step 0
        custom("Add to cart", visitor_id: "d"),
        custom("Purchase", visitor_id: "d", at: 5)
      ])

    report = FunnelReport.run(visits, funnel)

    assert report.name == "Checkout"
    assert Enum.map(report.steps, & &1.visitors) == [3, 2, 1]
    assert Enum.map(report.steps, & &1.of_first) == [100.0, 2 / 3 * 100, 1 / 3 * 100]
    assert hd(report.steps).drop_off == nil
    assert_in_delta Enum.at(report.steps, 1).drop_off, 33.33, 0.01
    assert Enum.at(report.steps, 2).drop_off == 50.0
    assert report.conversion_rate == 25.0
  end

  test "steps must happen within one visit", %{funnel: funnel} do
    visits =
      Visit.build([
        pageview("/products/mug", visitor_id: "a"),
        custom("Add to cart", visitor_id: "a", at: 3 * 3600),
        custom("Purchase", visitor_id: "a", at: 3 * 3600 + 10)
      ])

    assert Enum.map(FunnelReport.run(visits, funnel).steps, & &1.visitors) == [1, 0, 0]
  end

  test "an empty funnel has zeros, not errors", %{funnel: funnel} do
    report = FunnelReport.run([], funnel)
    assert Enum.map(report.steps, & &1.visitors) == [0, 0, 0]
    assert report.conversion_rate == 0.0
  end
end
