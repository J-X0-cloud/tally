defmodule Tally.Stats.FunnelTest do
  use ExUnit.Case, async: true

  alias Tally.Stats.Funnel

  doctest Funnel

  test "builds steps from goal definitions" do
    {:ok, funnel} =
      Funnel.new(%{
        name: "Checkout",
        steps: [%{type: :page, match: "/products/*"}, %{type: :event, match: "Purchase"}]
      })

    assert funnel.name == "Checkout"
    assert Enum.map(funnel.steps, & &1.type) == [:page, :event]
  end

  test "needs between two and eight steps" do
    one = [%{type: :event, match: "A"}]
    nine = for i <- 1..9, do: %{type: :event, match: "E#{i}"}

    assert Funnel.new(%{steps: one}) == {:error, "a funnel needs at least 2 steps"}
    assert Funnel.new(%{steps: nine}) == {:error, "a funnel can have at most 8 steps"}
    assert Funnel.new(%{steps: "x"}) == {:error, "steps must be a list"}
  end

  test "reports which step is invalid" do
    steps = [%{type: :event, match: "A"}, %{type: :page, match: "nope"}]

    assert Funnel.new(%{steps: steps}) ==
             {:error, "step 2: a page goal must match a path starting with /"}
  end

  test "parse/2 reads the compact form" do
    assert {:ok, funnel} =
             Funnel.parse("page:/products/*|event:Add to cart|event:Purchase", "Buy")

    assert funnel.name == "Buy"
    assert Enum.map(funnel.steps, & &1.match) == ["/products/*", "Add to cart", "Purchase"]

    assert {:error, message} = Funnel.parse("page:/a|click:b")
    assert message =~ "click:b"
  end
end
