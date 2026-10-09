defmodule Tally.Stats.GoalTest do
  use ExUnit.Case, async: true

  alias Tally.Events.Event
  alias Tally.Stats.Goal

  defp event(name, path),
    do: %Event{
      site: "s",
      name: name,
      path: path,
      visitor_id: "v",
      timestamp: ~U[2026-09-25 00:00:00Z]
    }

  test "event goals match the event name exactly" do
    goal = Goal.new!(%{type: :event, match: "Purchase"})
    assert goal.name == "Purchase"
    assert Goal.matches?(goal, event("Purchase", "/checkout"))
    refute Goal.matches?(goal, event("purchase", "/checkout"))
  end

  test "page goals match page views by pattern" do
    goal = Goal.new!(%{"type" => "page", "match" => "/products/*"})
    assert goal.name == "Visit /products/*"
    assert Goal.matches?(goal, event("pageview", "/products/ash-glaze-bowl-set"))
    refute Goal.matches?(goal, event("Add to cart", "/products/ash-glaze-bowl-set"))
    refute Goal.matches?(goal, event("pageview", "/shop/mugs"))
  end

  test "validates the definition" do
    assert Goal.new(%{type: "click", match: "x"}) == {:error, "type must be event or page"}

    assert Goal.new(%{type: :page, match: "cart"}) ==
             {:error, "a page goal must match a path starting with /"}

    assert Goal.new(%{type: :event, match: " "}) == {:error, "an event goal needs an event name"}

    assert Goal.new(%{type: :event, match: "pageview"}) ==
             {:error, "use a page goal to count page views"}

    assert_raise ArgumentError, ~r/invalid goal/, fn -> Goal.new!(%{type: :event}) end
  end
end
