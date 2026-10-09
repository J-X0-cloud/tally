defmodule Tally.Events.StoreTest do
  use Tally.StoreCase, async: false

  alias Tally.Events.Store

  @from ~U[2026-09-25 00:00:00Z]
  @to ~U[2026-09-26 00:00:00Z]

  test "returns a site's events in a half-open range, oldest first" do
    Store.insert_all([
      pageview("/b", at: 60),
      pageview("/a", at: 0),
      pageview("/late", at: ~U[2026-09-26 00:00:00Z]),
      pageview("/early", at: ~U[2026-09-24 23:59:59Z]),
      pageview("/other-site", site: "example.org", at: 30)
    ])

    assert Store.events("harrowfield.co", @from, @to) |> Enum.map(& &1.path) == ["/a", "/b"]
    assert Store.events("example.org", @from, @to) |> Enum.map(& &1.path) == ["/other-site"]
  end

  test "keeps events with identical timestamps" do
    Store.insert_all([pageview("/a", at: 5), pageview("/b", at: 5)])
    assert Store.count("harrowfield.co") == 2
  end

  test "prune/1 deletes events older than the cutoff" do
    Store.insert_all([
      pageview("/old", at: ~U[2025-01-01 00:00:00Z]),
      pageview("/new", at: 0)
    ])

    assert Store.prune(~U[2026-01-01 00:00:00Z]) == 1

    assert Store.events("harrowfield.co", ~U[2020-01-01 00:00:00Z], @to) |> Enum.map(& &1.path) ==
             ["/new"]
  end

  test "count/1 is per site" do
    Store.insert_all([pageview("/"), pageview("/", site: "example.org")])
    assert Store.count("harrowfield.co") == 1
    assert Store.count("nobody.example") == 0
  end
end
