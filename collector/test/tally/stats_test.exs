defmodule Tally.StatsTest do
  use Tally.StoreCase, async: false

  alias Tally.Events.Store
  alias Tally.Stats
  alias Tally.Stats.Query

  defp query(params) do
    {:ok, query} = Query.from_params("harrowfield.co", Map.put_new(params, "date", "2026-09-25"))
    query
  end

  setup do
    Store.insert_all([
      # this week
      pageview("/", visitor_id: "a", at: ~U[2026-09-24 10:00:00Z]),
      pageview("/products/mug", visitor_id: "a", at: ~U[2026-09-24 10:01:00Z]),
      custom("Add to cart", visitor_id: "a", at: ~U[2026-09-24 10:02:00Z]),
      custom("Purchase",
        visitor_id: "a",
        at: ~U[2026-09-24 10:03:00Z],
        revenue: %{amount: 64.0, currency: "USD"}
      ),
      pageview("/journal",
        visitor_id: "b",
        source: "Instagram",
        channel: "Organic Social",
        screen: "Desktop",
        at: ~U[2026-09-25 09:00:00Z]
      ),
      # the week before
      pageview("/", visitor_id: "c", at: ~U[2026-09-15 09:00:00Z]),
      # another site
      pageview("/", site: "example.org", visitor_id: "x", at: ~U[2026-09-24 09:00:00Z])
    ])

    :ok
  end

  test "aggregate/1 compares with the previous period" do
    result = Stats.aggregate(query(%{"period" => "7d"}))

    assert result.totals.visitors == 2
    assert result.totals.pageviews == 3
    assert result.totals.conversions == 1
    assert result.previous.visitors == 1
    assert result.deltas.visitors.text == "100%"
    assert result.deltas.visitors.good
    assert result.conversion_rate == 50.0
    assert result.revenue == [%{currency: "USD", amount: 64.0}]
  end

  test "filters narrow every report" do
    result = Stats.aggregate(query(%{"period" => "7d", "filters" => "screen==Desktop"}))
    assert result.totals.visitors == 1
    assert result.totals.conversions == 0
  end

  test "a visit that started before the period is not counted, nor split" do
    Store.insert_all([
      pageview("/late", visitor_id: "n", at: ~U[2026-09-18 23:50:00Z]),
      pageview("/after-midnight", visitor_id: "n", at: ~U[2026-09-19 00:05:00Z])
    ])

    pages = query(%{"period" => "7d"}) |> Stats.breakdown("entry_page") |> Enum.map(& &1.name)
    refute "/after-midnight" in pages
  end

  test "timeseries/1, breakdown/3, goals/1 and funnel/2" do
    q = query(%{"period" => "7d"})

    assert q |> Stats.timeseries() |> Enum.map(& &1.visitors) == [0, 0, 0, 0, 0, 1, 1]

    assert [%{name: "Google", visitors: 1}, %{name: "Instagram", visitors: 1}] =
             Stats.breakdown(q, "source")

    assert [%{name: "Purchase", uniques: 1, revenue: %{amount: 64.0}} | _] = Stats.goals(q)

    {:ok, funnel} = Tally.Sites.funnel("harrowfield.co", "Checkout")
    assert %{steps: steps} = Stats.funnel(q, funnel)
    assert Enum.map(steps, & &1.visitors) == [1, 1, 0, 0]
  end

  test "Query.from_params/2 validates parameters" do
    assert {:error, {:invalid, "period", _}} =
             Query.from_params("harrowfield.co", %{"period" => "1y"})

    assert {:error, {:invalid, "date", _}} =
             Query.from_params("harrowfield.co", %{"date" => "today"})

    assert {:error, {:invalid, "filters", _}} =
             Query.from_params("harrowfield.co", %{"filters" => "x"})

    assert {:ok, %Query{period: %{key: "30d"}}} = Query.from_params("harrowfield.co", %{})
  end
end
