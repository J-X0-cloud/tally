defmodule Tally.Stats do
  @moduledoc """
  Stats queries over stored events: totals with period comparison, timeseries, breakdowns, goal
  conversions and funnels. Each function loads the query's events, groups them into visits and
  applies the segment filters before aggregating.
  """

  alias Tally.Events.Store
  alias Tally.Sites
  alias Tally.Stats.Breakdown
  alias Tally.Stats.Delta
  alias Tally.Stats.Filter
  alias Tally.Stats.Funnel
  alias Tally.Stats.FunnelReport
  alias Tally.Stats.GoalReport
  alias Tally.Stats.Metrics
  alias Tally.Stats.Query
  alias Tally.Stats.Timeseries
  alias Tally.Stats.Visit

  @doc """
  The query's visits, sessionised and filtered.
  """
  @spec visits(Query.t()) :: [Visit.t()]
  def visits(%Query{site: site, period: period, filters: filters}) do
    # Load the visit timeout's worth of events before the period so a visit that started just
    # before the boundary keeps its real entry page and source; visits are then kept by start time.
    lead_in = DateTime.add(period.from, -Visit.timeout_seconds(), :second)

    site
    |> Store.events(lead_in, period.to)
    |> Visit.build()
    |> Enum.filter(&Tally.Stats.Period.contains?(period, &1.start))
    |> Filter.apply(filters)
  end

  @doc """
  Totals for the period and the previous period, with deltas, conversion rate and revenue.
  """
  @spec aggregate(Query.t()) :: map()
  def aggregate(%Query{site: site} = query) do
    goals = Sites.goals(site)
    visits = visits(query)
    current = Metrics.totals(visits, goals)
    previous = query |> Query.previous() |> visits() |> Metrics.totals(goals)

    %{
      totals: current,
      previous: previous,
      deltas:
        Map.new(Metrics.keys(), fn key ->
          {key, Delta.new(current[key], previous[key], Metrics.lower_is_better?(key))}
        end),
      conversion_rate: Metrics.conversion_rate(current),
      revenue: Metrics.revenue(visits)
    }
  end

  @doc "Metric values per bucket."
  @spec timeseries(Query.t()) :: [Timeseries.point()]
  def timeseries(%Query{site: site, period: period} = query) do
    query |> visits() |> Timeseries.run(period, Sites.goals(site))
  end

  @doc "Ranked rows for one dimension."
  @spec breakdown(Query.t(), String.t(), keyword()) :: [Breakdown.row()]
  def breakdown(%Query{} = query, dimension, opts \\ []) do
    query |> visits() |> Breakdown.run(dimension, opts)
  end

  @doc "Conversions for the site's configured goals."
  @spec goals(Query.t()) :: [GoalReport.row()]
  def goals(%Query{site: site} = query) do
    query |> visits() |> GoalReport.run(Sites.goals(site))
  end

  @doc "Step-by-step conversion for a funnel."
  @spec funnel(Query.t(), Funnel.t()) :: map()
  def funnel(%Query{} = query, %Funnel{} = funnel) do
    query |> visits() |> FunnelReport.run(funnel)
  end
end
