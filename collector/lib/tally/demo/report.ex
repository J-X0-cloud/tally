defmodule Tally.Demo.Report do
  @moduledoc """
  The demo dashboard's numbers, derived from `Tally.Demo.Simulation`: range bucketing, totals with
  period comparison, KPI deltas, breakdown tables, goal conversions and the checkout funnel.

  Ranges:

    * `today`: 24 hourly buckets (hours after the snapshot are `nil`), compared with yesterday up
      to the same hour;
    * `7d` / `30d`: daily buckets ending yesterday, compared with the period before;
    * `12m`: 52 weekly buckets, compared with the same weeks a year earlier.
  """

  alias Tally.Demo.Fixture
  alias Tally.Demo.Rng
  alias Tally.Demo.Simulation
  alias Tally.Stats.Delta
  alias Tally.Stats.Metrics

  @ranges [
    %{key: "today", label: "Today"},
    %{key: "7d", label: "7D"},
    %{key: "30d", label: "30D"},
    %{key: "12m", label: "12M"}
  ]
  @range_keys Enum.map(@ranges, & &1.key)

  # Visitors counted on several days are one unique visitor over the range; these are the typical
  # overlaps for multi-day and yearly ranges.
  @multi_day_unique_ratio 0.86
  @year_unique_ratio 0.8

  # About 5% of buyers place a second order in the same period.
  @repeat_order_factor 1.05

  @type range_key :: String.t()

  @doc "Range options in display order."
  def ranges, do: @ranges

  @doc "Range keys."
  def range_keys, do: @range_keys

  @doc "Validates a range key."
  @spec validate_range(String.t()) ::
          {:ok, range_key()} | {:error, {:invalid, String.t(), String.t()}}
  def validate_range(key) when key in @range_keys, do: {:ok, key}

  def validate_range(_),
    do: {:error, {:invalid, "range", "must be one of: #{Enum.join(@range_keys, ", ")}"}}

  @doc """
  Sums counts and averages bounce and duration weighted by visits. With `multi_day`, unique
  visitors are scaled by the typical overlap between days.
  """
  @spec aggregate([Simulation.point()], boolean()) :: Metrics.totals()
  def aggregate(points, multi_day \\ true) do
    sum = fn key -> Enum.reduce(points, 0, &(&2 + &1[key])) end
    visits = sum.(:visits)
    weighted = fn key -> Enum.reduce(points, 0, &(&2 + &1[key] * &1.visits)) / visits end

    %{
      visitors: sum.(:visitors) * if(multi_day, do: @multi_day_unique_ratio, else: 1),
      visits: visits,
      pageviews: sum.(:pageviews),
      bounce: weighted.(:bounce),
      duration: weighted.(:duration),
      conversions: sum.(:conversions)
    }
  end

  @doc """
  Everything the chart and KPI row need for one range.
  """
  @spec range(Simulation.t(), range_key()) :: map()
  def range(sim, "today") do
    %{hour: hour, minute: minute, today: today} = Fixture.snapshot()
    labels = Enum.map(0..23, &hour_label/1)
    upcoming = List.duplicate(nil, 23 - hour)

    totals = aggregate(sim.today_hours, false)
    prior = aggregate(Enum.take(sim.yesterday_hours, hour + 1), false)

    %{
      key: "today",
      current: sim.today_hours ++ upcoming,
      previous: sim.yesterday_hours,
      labels: labels,
      tips: Enum.map(labels, &("Today " <> &1)),
      span: "Today, #{day_label(today)} · until #{clock(hour, minute)}",
      interval: "Hourly",
      comparison: "vs. yesterday"
    }
    |> with_totals(totals, prior)
  end

  def range(sim, key) when key in ["7d", "30d"] do
    n = if key == "7d", do: 7, else: 30
    current = Enum.take(sim.days, -n)
    previous = sim.days |> Enum.take(-2 * n) |> Enum.take(n)
    first = hd(current).date
    last = List.last(current).date

    %{
      key: key,
      current: Enum.map(current, & &1.point),
      previous: Enum.map(previous, & &1.point),
      labels:
        Enum.map(current, fn %{date: date} ->
          if n == 7, do: Calendar.strftime(date, "%a %-d"), else: day_label(date)
        end),
      tips: Enum.map(current, &Calendar.strftime(&1.date, "%a, %b %-d")),
      span: "#{day_label(first)} – #{day_label(last)}, #{last.year}",
      interval: "Daily",
      comparison: "vs. previous period"
    }
    |> with_totals(
      aggregate(Enum.map(current, & &1.point)),
      aggregate(Enum.map(previous, & &1.point))
    )
  end

  def range(sim, "12m") do
    days = sim.days
    weeks = weeks(days, -364)
    prior_weeks = weeks(days, -728)
    week_point = fn week -> aggregate(Enum.map(week, & &1.point)) end
    first = weeks |> hd() |> hd()
    last = weeks |> List.last() |> List.last()

    %{
      key: "12m",
      current: Enum.map(weeks, week_point),
      previous: Enum.map(prior_weeks, week_point),
      labels:
        Enum.map(weeks, fn [%{date: date} | _] ->
          if date.day <= 7, do: Calendar.strftime(date, "%b"), else: ""
        end),
      tips:
        Enum.map(weeks, fn [%{date: date} | _] -> "Week of #{day_label(date)}, #{date.year}" end),
      span:
        "#{day_label(first.date)}, #{first.date.year} – #{day_label(last.date)}, #{last.date.year}",
      interval: "Weekly",
      comparison: "vs. previous year"
    }
    |> with_totals(year_totals(weeks), year_totals(prior_weeks))
  end

  @doc """
  Rows for one breakdown tab: the tab's typical shares applied to the range's visitors with ±10%
  deterministic variation, sorted by visitors, each with its share of visitors and its bar width
  relative to the top row.
  """
  @spec breakdown(map(), String.t(), String.t(), range_key()) :: [map()]
  def breakdown(range_data, dimension_key, tab_key, range_key) do
    {:ok, tab} = Fixture.tab(dimension_key, tab_key)
    total = range_data.totals.visitors
    rng = Rng.new(Rng.hash_seed("#{dimension_key}/#{tab_key}/#{range_key}"))

    {rows, _rng} =
      Enum.map_reduce(tab["rows"], rng, fn %{"name" => name, "share" => share}, rng ->
        {variation, rng} = Rng.uniform(rng, 0.9, 1.1)

        {code, label} =
          case String.split(name, "|", parts: 2) do
            [code, label] -> {code, label}
            [label] -> {nil, label}
          end

        {%{name: label, code: code, value: total * share * variation}, rng}
      end)

    rows = Enum.sort_by(rows, & &1.value, :desc)
    top = hd(rows).value

    Enum.map(rows, fn row ->
      Map.merge(row, %{share: row.value / total * 100, width: row.value / top * 100})
    end)
  end

  @doc """
  Goal conversions for a range, with revenue for goals that track it.
  """
  @spec goals(map(), range_key()) :: [map()]
  def goals(range_data, range_key) do
    visitors = range_data.totals.visitors
    average_order = Fixture.traffic().average_order
    rng = Rng.new(String.length(range_key) * 7 + 3)

    {rows, _rng} =
      Enum.map_reduce(Fixture.goals(), rng, fn goal, rng ->
        {variation, rng} = Rng.uniform(rng, 0.92, 1.08)
        uniques = visitors * goal["rate"] * variation

        row = %{
          name: goal["name"],
          uniques: uniques,
          total: uniques * goal["perVisitor"],
          conversion_rate: uniques / visitors * 100,
          revenue:
            if(goal["tracksRevenue"],
              do: uniques * @repeat_order_factor * average_order,
              else: nil
            )
        }

        {row, rng}
      end)

    rows
  end

  @doc """
  The checkout funnel for a range: visitors per step, % of the first step and drop-off since the
  previous step.
  """
  @spec funnel(map()) :: [map()]
  def funnel(range_data) do
    visitors = range_data.totals.visitors
    steps = Fixture.checkout_funnel()
    values = Enum.map(steps, &(visitors * &1["share"]))
    first = hd(values)

    steps
    |> Enum.zip(values)
    |> Enum.with_index()
    |> Enum.map(fn {{step, value}, index} ->
      %{
        name: step["name"],
        value: value,
        of_first: value / first * 100,
        drop_off: if(index == 0, do: nil, else: (1 - value / Enum.at(values, index - 1)) * 100)
      }
    end)
  end

  @doc "Hour labels as shown on the chart: 12am, 1am … 11pm."
  @spec hour_label(0..23) :: String.t()
  def hour_label(hour) do
    twelve = if rem(hour, 12) == 0, do: 12, else: rem(hour, 12)
    "#{twelve}#{if hour < 12, do: "am", else: "pm"}"
  end

  defp with_totals(range, totals, prior) do
    deltas =
      Map.new(Metrics.keys(), fn key ->
        {key, Delta.new(totals[key], prior[key], Metrics.lower_is_better?(key))}
      end)

    Map.merge(range, %{
      totals: totals,
      prior_totals: prior,
      deltas: deltas,
      conversion_rate: totals.conversions / totals.visitors * 100
    })
  end

  # 52 weekly buckets starting `offset` days from the end. The last week of the current year is
  # the final seven days.
  defp weeks(days, offset) do
    count = length(days)

    for w <- 0..51 do
      start = count + offset + w * 7
      Enum.slice(days, start, 7)
    end
  end

  defp year_totals(weeks) do
    totals = weeks |> List.flatten() |> Enum.map(& &1.point) |> aggregate()
    %{totals | visitors: totals.visitors * @year_unique_ratio}
  end

  defp day_label(date), do: Calendar.strftime(date, "%b %-d")

  defp clock(hour, minute) do
    twelve = if rem(hour, 12) == 0, do: 12, else: rem(hour, 12)
    suffix = if hour < 12, do: "am", else: "pm"
    "#{twelve}:#{minute |> Integer.to_string() |> String.pad_leading(2, "0")}#{suffix}"
  end
end
