defmodule Tally.Billing.PlansTest do
  use ExUnit.Case, async: true

  alias Tally.Billing.Plans

  doctest Plans

  # Captured from the TypeScript planPrice() the pricing page used before the move.
  @reference "test/fixtures/reference_quotes.json" |> File.read!() |> Jason.decode!()

  test "the catalog" do
    assert Enum.map(Plans.all(), & &1["id"]) == ["starter", "growth", "business"]
    assert Plans.volumes() |> length() == 8
    assert Plans.yearly_months_charged() == 10
    assert Enum.find(Plans.all(), & &1["popular"])["id"] == "growth"
    assert %{"feature" => "Sites", "values" => ["1", "5", "20"]} = hd(Plans.comparison())
  end

  test "every quote matches the previous pricing page" do
    for plan <- Plans.all(), {volume, index} <- Enum.with_index(Plans.volumes()) do
      expected = Enum.at(@reference[plan["name"]], index)

      for billing <- [:monthly, :yearly] do
        {:ok, quote} = Plans.quote(plan["id"], volume, billing)
        assert quote.price == expected[Atom.to_string(billing)]["price"]
        assert quote.note == expected[Atom.to_string(billing)]["note"]
      end
    end
  end

  test "price_table/0 has every tier for both billing periods" do
    [starter | _] = Plans.price_table()
    assert length(starter.prices) == 8

    assert %{volume: "10k", monthly: %{price: "$9"}, yearly: %{price: "$7.5"}} =
             hd(starter.prices)

    assert %{volume: "10M+", monthly: %{price: "Custom", monthly: nil}} =
             List.last(starter.prices)
  end

  test "quote/3 validates input" do
    assert Plans.quote("enterprise", "10k", :monthly) == {:error, {:not_found, "plan"}}
    assert {:error, {:invalid, "volume", _}} = Plans.quote("growth", "3M", :monthly)
  end

  test "limits and feature gates" do
    assert Plans.limits("starter").stats_api_per_hour == nil
    assert Plans.limits("growth").stats_api_per_hour == 600
    assert Plans.limits("business").stats_api_per_hour == 2000
    assert Plans.limits("business").retention_years == 5
    refute Plans.limits("growth").custom_properties
    assert Plans.cheapest_with(:funnels)["id"] == "growth"
    assert Plans.cheapest_with(:custom_properties)["id"] == "business"
    assert Plans.cheapest_with(:stats_api_per_hour)["id"] == "growth"
  end
end
