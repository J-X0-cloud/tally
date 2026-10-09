defmodule Tally.Billing.Plans do
  @moduledoc """
  The plan catalog: monthly prices per pageview tier, features, the comparison table, and the
  limits each plan enforces (sites, teammates, retention, Stats API rate, gated features).

  Read from `priv/billing/plans.json` at compile time. Yearly billing charges ten months for
  twelve.
  """

  @path Path.join([__DIR__, "..", "..", "..", "priv", "billing", "plans.json"])
  @external_resource @path
  @catalog @path |> File.read!() |> Jason.decode!()

  @plan_order Enum.map(@catalog["plans"], & &1["id"])

  @type plan_id :: String.t()
  @type billing :: :monthly | :yearly

  @doc "Monthly pageview tiers, e.g. `\"10k\"` … `\"10M+\"`. The last tier has no list price."
  @spec volumes() :: [String.t()]
  def volumes, do: @catalog["volumes"]

  @doc "Months charged for a year of yearly billing."
  @spec yearly_months_charged() :: pos_integer()
  def yearly_months_charged, do: @catalog["yearlyMonthsCharged"]

  @doc "All plans, cheapest first."
  @spec all() :: [map()]
  def all, do: @catalog["plans"]

  @doc "The feature comparison rows."
  @spec comparison() :: [map()]
  def comparison, do: @catalog["comparison"]

  @doc "Looks up a plan by id."
  @spec fetch(String.t()) :: {:ok, map()} | {:error, {:not_found, String.t()}}
  def fetch(id) do
    case Enum.find(all(), &(&1["id"] == id)) do
      nil -> {:error, {:not_found, "plan"}}
      plan -> {:ok, plan}
    end
  end

  @doc "A plan's limits, with atom keys."
  @spec limits(plan_id()) :: map()
  def limits(id) do
    {:ok, plan} = fetch(id)

    %{
      sites: plan["limits"]["sites"],
      teammates: plan["limits"]["teammates"],
      retention_years: plan["limits"]["retentionYears"],
      stats_api_per_hour: plan["limits"]["statsApiPerHour"],
      funnels: plan["limits"]["funnels"],
      revenue_goals: plan["limits"]["revenueGoals"],
      shared_links: plan["limits"]["sharedLinks"],
      custom_properties: plan["limits"]["customProperties"],
      managed_proxy: plan["limits"]["managedProxy"]
    }
  end

  @doc """
  Whether `plan` is at least `minimum` in the catalog order.

      iex> Tally.Billing.Plans.at_least?("business", "growth")
      true
      iex> Tally.Billing.Plans.at_least?("starter", "growth")
      false
  """
  @spec at_least?(plan_id(), plan_id()) :: boolean()
  def at_least?(plan, minimum) do
    rank(plan) >= rank(minimum)
  end

  @doc """
  The cheapest plan that includes a limit flag such as `:funnels`.
  """
  @spec cheapest_with(atom()) :: map() | nil
  def cheapest_with(feature) do
    Enum.find(all(), &(limits(&1["id"])[feature] not in [nil, false]))
  end

  @doc """
  The displayed price and note for a plan at a volume tier.

      iex> Tally.Billing.Plans.quote("growth", "100k", :yearly)
      {:ok, %{price: "$24.17", note: "$290 billed yearly · 100k pageviews", monthly: 29}}
  """
  @spec quote(plan_id(), String.t(), billing()) :: {:ok, map()} | {:error, term()}
  def quote(plan_id, volume, billing) when billing in [:monthly, :yearly] do
    with {:ok, plan} <- fetch(plan_id),
         {:ok, index} <- volume_index(volume) do
      {:ok, price(Enum.at(plan["prices"], index), volume, billing)}
    end
  end

  @doc """
  Every price for every plan, tier and billing period, keyed for a pricing page that switches
  between them without another request.
  """
  @spec price_table() :: [map()]
  def price_table do
    Enum.map(all(), fn plan ->
      %{
        id: plan["id"],
        name: plan["name"],
        description: plan["description"],
        features: plan["features"],
        popular: plan["popular"],
        prices:
          plan["prices"]
          |> Enum.zip(volumes())
          |> Enum.map(fn {monthly, volume} ->
            %{
              volume: volume,
              monthly: price(monthly, volume, :monthly),
              yearly: price(monthly, volume, :yearly)
            }
          end)
      }
    end)
  end

  defp price(nil, _volume, _billing),
    do: %{price: "Custom", note: "Talk to us about volume pricing", monthly: nil}

  defp price(monthly, volume, :monthly),
    do: %{price: "$#{monthly}", note: "Billed monthly · #{volume} pageviews", monthly: monthly}

  defp price(monthly, volume, :yearly) do
    yearly = monthly * yearly_months_charged()

    %{
      price: "$" <> trim_cents(yearly / 12),
      note: "$#{yearly} billed yearly · #{volume} pageviews",
      monthly: monthly
    }
  end

  # 11.666… -> "11.67", 7.5 -> "7.5", 15.0 -> "15"
  defp trim_cents(amount) do
    amount
    |> :erlang.float_to_binary(decimals: 2)
    |> String.replace(~r/\.?0+$/, "")
  end

  defp volume_index(volume) do
    case Enum.find_index(volumes(), &(&1 == volume)) do
      nil -> {:error, {:invalid, "volume", "must be one of: #{Enum.join(volumes(), ", ")}"}}
      index -> {:ok, index}
    end
  end

  defp rank(plan), do: Enum.find_index(@plan_order, &(&1 == plan)) || -1
end
