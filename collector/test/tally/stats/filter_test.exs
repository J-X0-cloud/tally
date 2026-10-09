defmodule Tally.Stats.FilterTest do
  use ExUnit.Case, async: true

  import Tally.Factory

  alias Tally.Stats.Filter
  alias Tally.Stats.Visit

  doctest Filter

  defp visits do
    Visit.build([
      pageview("/", visitor_id: "insta", source: "Instagram", screen: "Mobile"),
      pageview("/products/mug", visitor_id: "insta", at: 30),
      pageview("/journal",
        visitor_id: "google",
        source: "Google",
        screen: "Desktop",
        country: "CA"
      ),
      pageview("/products/bowl",
        visitor_id: "pin",
        source: "Pinterest",
        screen: "Mobile",
        utm: %{"campaign" => "pins-autumn-table"}
      ),
      custom("Add to cart", visitor_id: "pin", path: "/products/bowl", at: 20)
    ])
  end

  defp ids(filter_string) do
    {:ok, filters} = Filter.parse(filter_string)
    visits() |> Filter.apply(filters) |> Enum.map(& &1.visitor_id) |> Enum.sort()
  end

  test "is / is not on visit dimensions" do
    assert ids("source==Instagram|Pinterest") == ["insta", "pin"]
    assert ids("source!=Instagram") == ["google", "pin"]
    assert ids("country==CA") == ["google"]
    assert ids("utm_campaign==pins-autumn-table") == ["pin"]
  end

  test "contains is case-insensitive" do
    assert ids("source~=gram") == ["insta"]
    assert ids("source~=GOO") == ["google"]
  end

  test "page keeps visits that viewed a matching page" do
    assert ids("page==/products/*") == ["insta", "pin"]
    assert ids("page!=/products/*") == ["google"]
    assert ids("entry_page==/products/*") == ["pin"]
  end

  test "event keeps visits with the custom event" do
    assert ids("event==Add to cart") == ["pin"]
  end

  test "clauses are combined with and" do
    assert ids("screen==Mobile;page==/products/*;source==Instagram|Pinterest") == ["insta", "pin"]
    assert ids("screen==Mobile;source==Google") == []
  end

  test "an empty filter keeps everything" do
    assert ids("") == ["google", "insta", "pin"]
    assert Filter.parse(nil) == {:ok, []}
  end

  test "rejects unknown dimensions and malformed clauses" do
    assert {:error, {:invalid, "filters", "unknown dimension \"ip\""}} =
             Filter.parse("ip==1.2.3.4")

    assert {:error, {:invalid, "filters", message}} = Filter.parse("source=Google")
    assert message =~ "dimension==value"

    assert {:error, {:invalid, "filters", "source needs at least one value"}} =
             Filter.parse("source==|")

    many = Enum.map_join(1..11, ";", fn _ -> "screen==Mobile" end)
    assert {:error, {:invalid, "filters", "at most 10 clauses are allowed"}} = Filter.parse(many)
  end
end
