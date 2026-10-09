defmodule Tally.Stats.Metrics do
  @moduledoc """
  The six dashboard metrics and how they are computed from visits.

  | key           | meaning                                                         |
  | ------------- | --------------------------------------------------------------- |
  | `visitors`    | unique visitor ids                                              |
  | `visits`      | visits (sessions)                                               |
  | `pageviews`   | page views                                                      |
  | `bounce`      | % of visits that bounced (lower is better)                      |
  | `duration`    | average visit length, seconds                                   |
  | `conversions` | unique visitors who completed at least one goal                 |

  Visitor ids rotate daily, so a person who visits on two days counts as two visitors over a
  multi-day period. That is the cost of not storing anything on the device.
  """

  alias Tally.Stats.Goal
  alias Tally.Stats.Visit

  @definitions [
    %{key: :visitors, label: "Unique visitors", format: :number, lower_is_better: false},
    %{key: :visits, label: "Total visits", format: :number, lower_is_better: false},
    %{key: :pageviews, label: "Pageviews", format: :number, lower_is_better: false},
    %{key: :bounce, label: "Bounce rate", format: :percent, lower_is_better: true},
    %{key: :duration, label: "Visit duration", format: :duration, lower_is_better: false},
    %{key: :conversions, label: "Conversions", format: :number, lower_is_better: false}
  ]

  @keys Enum.map(@definitions, & &1.key)

  @type key :: :visitors | :visits | :pageviews | :bounce | :duration | :conversions
  @type totals :: %{key() => number()}

  @doc "Metric definitions in display order."
  def definitions, do: @definitions

  @doc "Metric keys in display order."
  def keys, do: @keys

  @doc "Looks up a metric key from its string name."
  @spec parse_key(String.t()) :: {:ok, key()} | :error
  def parse_key(name) do
    case Enum.find(@keys, &(Atom.to_string(&1) == name)) do
      nil -> :error
      key -> {:ok, key}
    end
  end

  @doc "Whether a lower value of the metric is an improvement."
  @spec lower_is_better?(key()) :: boolean()
  def lower_is_better?(key), do: Enum.find(@definitions, &(&1.key == key)).lower_is_better

  @doc """
  Totals for a list of visits. `goals` decide what counts as a conversion.
  """
  @spec totals([Visit.t()], [Goal.t()]) :: totals()
  def totals(visits, goals \\ []) do
    visit_count = length(visits)

    %{
      visitors: visits |> Enum.uniq_by(& &1.visitor_id) |> length(),
      visits: visit_count,
      pageviews: Enum.sum_by(visits, & &1.pageviews),
      bounce: percent(Enum.count(visits, &Visit.bounce?/1), visit_count),
      duration: average(Enum.map(visits, &Visit.duration/1)),
      conversions: converted_visitors(visits, goals)
    }
  end

  @doc """
  Conversion rate: converted visitors as a % of all visitors.
  """
  @spec conversion_rate(totals()) :: float()
  def conversion_rate(%{conversions: conversions, visitors: visitors}),
    do: percent(conversions, visitors)

  @doc """
  Revenue attached to events in the visits, summed per currency.
  """
  @spec revenue([Visit.t()]) :: [%{currency: String.t(), amount: float()}]
  def revenue(visits) do
    visits
    |> Enum.flat_map(& &1.events)
    |> Enum.filter(& &1.revenue)
    |> Enum.group_by(& &1.revenue.currency, & &1.revenue.amount)
    |> Enum.map(fn {currency, amounts} ->
      %{currency: currency, amount: Enum.sum(amounts) / 1}
    end)
    |> Enum.sort_by(&{-&1.amount, &1.currency})
  end

  @doc false
  def percent(_part, 0), do: 0.0
  def percent(part, whole), do: part / whole * 100

  defp average([]), do: 0.0
  defp average(values), do: Enum.sum(values) / length(values)

  defp converted_visitors(_visits, []), do: 0

  defp converted_visitors(visits, goals) do
    visits
    |> Enum.filter(fn visit ->
      Enum.any?(visit.events, fn event -> Enum.any?(goals, &Goal.matches?(&1, event)) end)
    end)
    |> Enum.uniq_by(& &1.visitor_id)
    |> length()
  end
end
