defmodule Tally.Stats.VisitTest do
  use ExUnit.Case, async: true

  import Tally.Factory

  alias Tally.Stats.Visit

  test "groups a visitor's events into one visit with entry and exit pages" do
    [visit] =
      Visit.build([
        pageview("/cart", at: 120),
        pageview("/", at: 0, source: "Instagram", channel: "Organic Social"),
        custom("Add to cart", path: "/products/mug", at: 90),
        pageview("/products/mug", at: 60)
      ])

    assert visit.entry_page == "/"
    assert visit.exit_page == "/cart"
    assert visit.pageviews == 3
    assert visit.custom_events == 1
    assert visit.source == "Instagram"
    assert Visit.duration(visit) == 120
    assert Visit.pages(visit) == ["/", "/products/mug", "/cart"]
    refute Visit.bounce?(visit)
  end

  test "starts a new visit after 30 minutes of inactivity" do
    visits =
      Visit.build([
        pageview("/", at: 0),
        pageview("/a", at: 30 * 60),
        pageview("/b", at: 30 * 60 + 30 * 60 + 1)
      ])

    assert Enum.map(visits, &Visit.pages/1) == [["/", "/a"], ["/b"]]
  end

  test "keeps visitors apart and orders visits by start" do
    visits =
      Visit.build([
        pageview("/late", visitor_id: "a", at: 500),
        pageview("/early", visitor_id: "b", at: 10)
      ])

    assert Enum.map(visits, & &1.visitor_id) == ["b", "a"]
  end

  test "a single page view bounces; a custom event saves it" do
    [single] = Visit.build([pageview("/")])
    [engaged] = Visit.build([pageview("/"), custom("Newsletter signup", at: 20)])

    assert Visit.bounce?(single)
    refute Visit.bounce?(engaged)
  end

  test "a visit without page views takes its pages from its events" do
    [visit] = Visit.build([custom("Outbound link", path: "/about")])
    assert visit.entry_page == "/about"
    assert visit.pageviews == 0
  end
end
