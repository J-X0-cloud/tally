defmodule Tally.Demo do
  @moduledoc """
  The public demo: Harrowfield Supply's dashboard, built from the seeded traffic model.

  The model and every derived report are computed once per node and kept in `:persistent_term`;
  they never change while the node runs.
  """

  alias Tally.Demo.Fixture
  alias Tally.Demo.Report
  alias Tally.Demo.Simulation
  alias Tally.Stats.Metrics

  @cache_key {__MODULE__, :dashboard}

  @doc "The demo site."
  @spec site() :: map()
  def site, do: Fixture.site()

  @doc """
  The full dashboard: site, metric definitions, range options, breakdown dimensions, and for every
  range its chart data, totals, deltas, breakdown rows, goals and funnel.
  """
  @spec dashboard() :: map()
  def dashboard do
    case :persistent_term.get(@cache_key, nil) do
      nil ->
        dashboard = build()
        :persistent_term.put(@cache_key, dashboard)
        dashboard

      dashboard ->
        dashboard
    end
  end

  @doc "One range of the dashboard."
  @spec range(String.t()) :: {:ok, map()} | {:error, term()}
  def range(key) do
    with {:ok, key} <- Report.validate_range(key) do
      {:ok, dashboard().data[key]}
    end
  end

  @doc "Breakdown rows for one dimension tab and range."
  @spec breakdown(String.t(), String.t(), String.t()) :: {:ok, [map()]} | {:error, term()}
  def breakdown(dimension, tab, range_key) do
    with {:ok, range} <- range(range_key),
         {:ok, _tab} <- Fixture.tab(dimension, tab) do
      {:ok, range.breakdowns[dimension][tab]}
    end
  end

  @doc "The realtime card: current visitors, visitors-per-minute spark and the live feed."
  @spec realtime() :: map()
  def realtime do
    realtime = Fixture.realtime()

    %{
      current_visitors: site()["currentVisitors"],
      spark: realtime["spark"],
      feed: realtime["feed"]
    }
  end

  @doc "Drops the cached dashboard (tests, or after changing the fixture in a running node)."
  @spec reset() :: :ok
  def reset do
    :persistent_term.erase(@cache_key)
    :ok
  end

  defp build do
    sim = Simulation.run()

    data =
      Map.new(Report.range_keys(), fn key ->
        range = Report.range(sim, key)

        breakdowns =
          Map.new(Fixture.dimensions(), fn dimension ->
            {dimension["key"],
             Map.new(dimension["tabs"], fn tab ->
               {tab["key"], Report.breakdown(range, dimension["key"], tab["key"], key)}
             end)}
          end)

        {key,
         Map.merge(range, %{
           breakdowns: breakdowns,
           goals: Report.goals(range, key),
           funnel: Report.funnel(range)
         })}
      end)

    %{
      site: site(),
      metrics: Metrics.definitions(),
      ranges: Report.ranges(),
      default_range: "30d",
      default_metric: "visitors",
      dimensions: Enum.map(Fixture.dimensions(), &dimension_meta/1),
      realtime: realtime(),
      data: data
    }
  end

  # Tabs without their seed rows: the client only needs labels and display hints.
  defp dimension_meta(dimension) do
    %{
      key: dimension["key"],
      title: dimension["title"],
      column: dimension["column"],
      tabs:
        Enum.map(dimension["tabs"], fn tab ->
          %{
            key: tab["key"],
            label: tab["label"],
            heading: tab["heading"],
            mono: Map.get(tab, "mono", false),
            chip: Map.get(tab, "chip")
          }
        end)
    }
  end
end
