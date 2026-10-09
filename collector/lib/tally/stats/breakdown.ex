defmodule Tally.Stats.Breakdown do
  @moduledoc """
  Ranked breakdown tables: the rows behind the Sources, Pages, Locations and Devices panels.

  Visit dimensions (see `Tally.Stats.Filter.visit_value/2`) group visits by their own attribute.
  Three dimensions look at individual events instead:

    * `page` counts page views per path;
    * `event` counts custom events per name;
    * `prop:<name>` counts custom events per value of a custom property.

  Rows are ranked by visitors, then name, and carry each row's share of all visitors.
  """

  alias Tally.Events.Event
  alias Tally.Stats.Filter
  alias Tally.Stats.Metrics
  alias Tally.Stats.Visit

  @event_dimensions ~w(page event)
  @dimensions ~w(channel source utm_source utm_medium utm_campaign utm_term utm_content
                 page entry_page exit_page country screen browser os event)

  @type row :: %{
          name: String.t(),
          visitors: non_neg_integer(),
          visits: non_neg_integer(),
          pageviews: non_neg_integer(),
          events: non_neg_integer(),
          bounce: float(),
          share: float()
        }

  @doc "Dimensions that can be broken down (plus `prop:<name>`)."
  def dimensions, do: @dimensions

  @doc "Validates a dimension name."
  @spec validate(String.t()) :: {:ok, String.t()} | {:error, {:invalid, String.t(), String.t()}}
  def validate("prop:" <> name = dimension) when byte_size(name) in 1..64, do: {:ok, dimension}
  def validate(dimension) when dimension in @dimensions, do: {:ok, dimension}

  def validate(_),
    do:
      {:error,
       {:invalid, "property", "must be one of #{Enum.join(@dimensions, ", ")}, or prop:<name>"}}

  @doc """
  Breaks down `visits` by `dimension`. Options: `:limit` (default 10) and `:page` (1-based).
  """
  @spec run([Visit.t()], String.t(), keyword()) :: [row()]
  def run(visits, dimension, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    page = Keyword.get(opts, :page, 1)
    total_visitors = visits |> Enum.uniq_by(& &1.visitor_id) |> length()

    visits
    |> rows(dimension)
    |> Enum.map(fn row -> Map.put(row, :share, Metrics.percent(row.visitors, total_visitors)) end)
    |> Enum.sort_by(&{-&1.visitors, -&1.pageviews, &1.name})
    |> Enum.drop((page - 1) * limit)
    |> Enum.take(limit)
  end

  defp rows(visits, "prop:" <> _ = dimension), do: event_rows(visits, dimension)

  defp rows(visits, dimension) when dimension in @event_dimensions,
    do: event_rows(visits, dimension)

  defp rows(visits, dimension), do: visit_rows(visits, dimension)

  defp visit_rows(visits, dimension) do
    visits
    |> Enum.group_by(&(Filter.visit_value(&1, dimension) || none_label(dimension)))
    |> Enum.map(fn {name, group} ->
      %{
        name: name,
        visitors: group |> Enum.uniq_by(& &1.visitor_id) |> length(),
        visits: length(group),
        pageviews: Enum.sum_by(group, & &1.pageviews),
        events: Enum.sum_by(group, &length(&1.events)),
        bounce: Metrics.percent(Enum.count(group, &Visit.bounce?/1), length(group))
      }
    end)
  end

  defp event_rows(visits, dimension) do
    visits
    |> Enum.flat_map(fn visit -> Enum.map(visit.events, &{visit, &1}) end)
    |> Enum.flat_map(fn {visit, event} ->
      case event_key(event, dimension) do
        nil -> []
        key -> [{key, visit, event}]
      end
    end)
    |> Enum.group_by(&elem(&1, 0))
    |> Enum.map(fn {name, entries} ->
      group_visits = entries |> Enum.map(&elem(&1, 1)) |> Enum.uniq()
      group_events = Enum.map(entries, &elem(&1, 2))

      %{
        name: name,
        visitors: group_visits |> Enum.uniq_by(& &1.visitor_id) |> length(),
        visits: length(group_visits),
        pageviews: Enum.count(group_events, &Event.pageview?/1),
        events: length(group_events),
        bounce: Metrics.percent(Enum.count(group_visits, &Visit.bounce?/1), length(group_visits))
      }
    end)
  end

  defp event_key(event, "page"), do: if(Event.pageview?(event), do: event.path)
  defp event_key(event, "event"), do: if(Event.pageview?(event), do: nil, else: event.name)

  defp event_key(event, "prop:" <> name) do
    case Map.fetch(event.props, name) do
      {:ok, value} when not is_nil(value) -> to_string(value)
      _ -> nil
    end
  end

  defp none_label("country"), do: "Unknown"
  defp none_label("utm_" <> _), do: "(none)"
  defp none_label(_), do: "Other"
end
