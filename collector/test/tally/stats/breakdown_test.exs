defmodule Tally.Stats.BreakdownTest do
  use ExUnit.Case, async: true

  import Tally.Factory

  alias Tally.Stats.Breakdown
  alias Tally.Stats.Visit

  defp visits do
    Visit.build([
      pageview("/", visitor_id: "a", source: "Google", country: "US"),
      pageview("/shop/mugs", visitor_id: "a", at: 10),
      pageview("/", visitor_id: "b", source: "Google", country: nil, browser: "Chrome"),
      pageview("/journal", visitor_id: "c", source: "Instagram", utm: %{"campaign" => "reels"}),
      custom("Purchase", visitor_id: "c", at: 30, props: %{"collection" => "fall-glaze"}),
      custom("Purchase", visitor_id: "a", at: 40, props: %{"collection" => "fall-glaze"}),
      custom("Newsletter signup", visitor_id: "b", at: 50, props: %{"form" => "footer"})
    ])
  end

  test "visit dimensions rank by visitors with shares" do
    assert [google, instagram] = Breakdown.run(visits(), "source")
    assert %{name: "Google", visitors: 2, visits: 2, pageviews: 3} = google
    assert_in_delta google.share, 66.67, 0.01
    assert %{name: "Instagram", visitors: 1} = instagram
  end

  test "missing values get a label" do
    names = visits() |> Breakdown.run("country") |> Enum.map(& &1.name)
    assert "Unknown" in names
    assert visits() |> Breakdown.run("utm_campaign") |> Enum.map(& &1.name) == ["(none)", "reels"]
  end

  test "page counts page views per path" do
    rows = Breakdown.run(visits(), "page")
    assert [%{name: "/", visitors: 2, pageviews: 2} | _] = rows
    assert Enum.map(rows, & &1.name) == ["/", "/journal", "/shop/mugs"]
  end

  test "entry and exit pages" do
    assert [%{name: "/", visitors: 2} | _] = Breakdown.run(visits(), "entry_page")
    exits = visits() |> Breakdown.run("exit_page") |> Enum.map(& &1.name)
    assert Enum.sort(exits) == ["/", "/journal", "/shop/mugs"]
  end

  test "event and custom property breakdowns" do
    assert [%{name: "Purchase", visitors: 2, events: 2}, %{name: "Newsletter signup"}] =
             Breakdown.run(visits(), "event")

    assert [%{name: "fall-glaze", visitors: 2}] = Breakdown.run(visits(), "prop:collection")
    assert [%{name: "footer"}] = Breakdown.run(visits(), "prop:form")
  end

  test "limit and page" do
    assert [%{name: "/"}] = Breakdown.run(visits(), "page", limit: 1)
    assert [%{name: "/journal"}] = Breakdown.run(visits(), "page", limit: 1, page: 2)
    assert [] = Breakdown.run(visits(), "page", limit: 5, page: 3)
  end

  test "validate/1" do
    assert Breakdown.validate("source") == {:ok, "source"}
    assert Breakdown.validate("prop:collection") == {:ok, "prop:collection"}
    assert {:error, {:invalid, "property", _}} = Breakdown.validate("ip")
    assert {:error, {:invalid, "property", _}} = Breakdown.validate("prop:")
  end
end
