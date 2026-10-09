defmodule Tally.SitesTest do
  use ExUnit.Case, async: true

  alias Tally.Sites

  test "domains come from configuration" do
    assert Sites.domains() == ["harrowfield.co", "example.org"]
  end

  test "normalize/1 strips scheme, www, port and path" do
    assert Sites.normalize(" https://WWW.Harrowfield.co:443/shop?x=1 ") == "harrowfield.co"
    assert Sites.normalize("harrowfield.co") == "harrowfield.co"
  end

  test "allowed?/1" do
    assert Sites.allowed?("harrowfield.co")
    assert Sites.allowed?("www.harrowfield.co")
    refute Sites.allowed?("evil.example")
    refute Sites.allowed?(nil)
  end

  test "fetch/1" do
    assert Sites.fetch("WWW.example.org") == {:ok, "example.org"}
    assert Sites.fetch("nope.example") == {:error, {:not_found, "site"}}
  end

  test "goals and funnels are built from configuration" do
    goals = Sites.goals("harrowfield.co")
    assert Enum.map(goals, & &1.name) |> Enum.take(2) == ["Purchase", "Add to cart"]
    assert Enum.find(goals, &(&1.type == :page)).match == "/checkout/thank-you"

    assert {:ok, funnel} = Sites.funnel("harrowfield.co", "checkout")
    assert length(funnel.steps) == 4
    assert Sites.funnel("harrowfield.co", "nope") == {:error, {:not_found, "funnel"}}
  end
end
