defmodule TallyWeb.StatsController do
  @moduledoc """
  The Stats API (`/api/v1/stats/:site/...`), authenticated with a Bearer key and rate limited per
  plan. Every endpoint accepts `period`, `date`, `from` / `to` and `filters` (see
  `Tally.Stats.Query`).
  """
  use TallyWeb, :controller

  alias Tally.Billing.Plans
  alias Tally.Sites
  alias Tally.Stats
  alias Tally.Stats.Breakdown
  alias Tally.Stats.Funnel
  alias Tally.Stats.Period
  alias Tally.Stats.Query
  alias TallyWeb.JSON

  @doc "`GET .../aggregate`: totals, previous-period totals, deltas, conversion rate, revenue."
  def aggregate(conn, params) do
    with {:ok, query} <- query(params) do
      render_stats(conn, query, Stats.aggregate(query))
    end
  end

  @doc "`GET .../timeseries`: one point per hour, day, week or month."
  def timeseries(conn, params) do
    with {:ok, query} <- query(params) do
      render_stats(conn, query, %{points: Stats.timeseries(query)})
    end
  end

  @doc "`GET .../breakdown?property=source&limit=10&page=1`"
  def breakdown(conn, params) do
    with {:ok, query} <- query(params),
         {:ok, property} <- required(params, "property"),
         {:ok, property} <- Breakdown.validate(property),
         :ok <- allow_property(conn.assigns.plan, property),
         {:ok, limit} <- integer(params, "limit", 10, 1..100),
         {:ok, page} <- integer(params, "page", 1, 1..1000) do
      rows = Stats.breakdown(query, property, limit: limit, page: page)
      render_stats(conn, query, %{property: property, page: page, rows: rows})
    end
  end

  @doc "`GET .../goals`: conversions for the site's goals."
  def goals(conn, params) do
    with {:ok, query} <- query(params) do
      render_stats(conn, query, %{goals: Stats.goals(query)})
    end
  end

  @doc """
  `GET .../funnel?name=Checkout` for a configured funnel, or
  `GET .../funnel?steps=page:/products/*|event:Purchase` for an ad-hoc one.
  """
  def funnel(conn, params) do
    with :ok <- allow(conn.assigns.plan, :funnels, "Funnels"),
         {:ok, query} <- query(params),
         {:ok, funnel} <- funnel_definition(query.site, params) do
      render_stats(conn, query, %{funnel: Stats.funnel(query, funnel)})
    end
  end

  @doc "`GET .../realtime`: visitors active in the last five minutes."
  def realtime(conn, %{"site" => site}) do
    with {:ok, site} <- Sites.fetch(site) do
      json(conn, JSON.camelize(Tally.Live.snapshot(site)))
    end
  end

  defp query(%{"site" => site} = params) do
    with {:ok, site} <- Sites.fetch(site) do
      Query.from_params(site, params)
    end
  end

  defp funnel_definition(site, params) do
    case params do
      %{"steps" => steps} when is_binary(steps) and steps != "" ->
        case Funnel.parse(steps, Map.get(params, "name", "Custom funnel")) do
          {:ok, funnel} -> {:ok, funnel}
          {:error, message} -> {:error, {:invalid, "steps", message}}
        end

      %{"name" => name} when is_binary(name) ->
        Sites.funnel(site, name)

      _ ->
        case Sites.funnels(site) do
          [first | _] -> {:ok, first}
          [] -> {:error, {:bad_request, "pass steps=page:/path|event:Name or a funnel name"}}
        end
    end
  end

  defp allow_property(plan, "prop:" <> _),
    do: allow(plan, :custom_properties, "Custom properties")

  defp allow_property(_plan, _property), do: :ok

  defp allow(plan, feature, label) do
    if Plans.limits(plan)[feature] do
      :ok
    else
      {:error, {:plan_required, label, Plans.cheapest_with(feature)["name"]}}
    end
  end

  defp render_stats(conn, query, body) do
    meta = %{
      site: query.site,
      period: Period.to_map(query.period),
      filters: Enum.map(query.filters, &Map.from_struct/1)
    }

    json(conn, JSON.camelize(Map.merge(meta, body)))
  end
end
