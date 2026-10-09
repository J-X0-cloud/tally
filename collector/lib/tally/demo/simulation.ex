defmodule Tally.Demo.Simulation do
  @moduledoc """
  The seeded traffic model behind the demo dashboard: 760 days of traffic ending yesterday, plus
  today's hours up to the snapshot hour and all of yesterday's hours for comparison.

  Each day's visitors follow a growth curve, a weekday pattern, a gentle yearly season with a
  December gifting lift, launch and newsletter spikes, and ±10% noise. Visits, page views, bounce
  rate, duration and conversions are drawn around realistic ratios. Draws happen in a fixed order
  from one generator, so the model is fully determined by its seed.

  A traffic point is a map of the six dashboard metrics (bounce in %, duration in seconds).
  """

  alias Tally.Demo.Fixture
  alias Tally.Demo.Rng

  @type point :: %{
          visitors: float(),
          visits: float(),
          pageviews: float(),
          bounce: float(),
          duration: float(),
          conversions: float()
        }

  @type day :: %{date: Date.t(), point: point()}
  @type t :: %{days: [day()], today_hours: [point()], yesterday_hours: [point()]}

  @today_base_visitors 1780

  @doc """
  Runs the model with the fixture's parameters.
  """
  @spec run() :: t()
  def run, do: run(Fixture.traffic(), Fixture.snapshot())

  @doc """
  Runs the model with explicit parameters (see `Tally.Demo.Fixture.traffic/0`).
  """
  @spec run(map(), map()) :: t()
  def run(traffic, %{today: today, hour: hour}) do
    rng = Rng.new(traffic.seed)
    count = traffic.day_count

    {days, rng} =
      Enum.map_reduce(0..(count - 1), rng, fn i, rng ->
        date = Date.add(today, -(count - i))
        {point, rng} = day_point(traffic, i, date, rng)
        {%{date: date, point: point}, rng}
      end)

    today_visitors = @today_base_visitors * weekday(traffic, today)
    {today_hours, rng} = hourly(traffic, today_visitors, rng)
    {yesterday_hours, _rng} = hourly(traffic, List.last(days).point.visitors, rng)

    %{days: days, today_hours: Enum.take(today_hours, hour + 1), yesterday_hours: yesterday_hours}
  end

  @doc "Day-of-week multiplier, Monday first."
  @spec weekday(map(), Date.t()) :: float()
  def weekday(traffic, date), do: elem(traffic.weekday, Date.day_of_week(date) - 1)

  # The arithmetic below keeps the original operand order so results match the reference model
  # to the last digit.
  defp day_point(traffic, i, date, rng) do
    t = i / traffic.day_count
    base = 520 + 1180 * :math.pow(t, 1.15)
    season = 1 + 0.09 * :math.sin(Date.day_of_year(date) / 365 * 2 * :math.pi() + 1.1)
    season = if date.month == 12 and date.day > 12, do: season * 1.18, else: season
    spike = Map.get(traffic.spikes, date, 1)

    {noise, rng} = Rng.uniform(rng, 0.9, 1.1)
    visitors = base * weekday(traffic, date) * season * noise * spike
    {visit_ratio, rng} = Rng.uniform(rng, 1.15, 1.22)
    visits = visitors * visit_ratio
    {rate, rng} = Rng.uniform(rng, 2.3, 3.2)
    conversion_rate = rate * if(spike > 1.5, do: 1.35, else: 1)
    {pages_per_visit, rng} = Rng.uniform(rng, 2.55, 3.1)
    {bounce, rng} = Rng.uniform(rng, 37, 45)
    {duration, rng} = Rng.uniform(rng, 128, 176)

    point = %{
      visitors: visitors,
      visits: visits,
      pageviews: visits * pages_per_visit,
      bounce: bounce - if(spike > 1, do: 3, else: 0),
      duration: duration,
      conversions: visitors * conversion_rate / 100
    }

    {point, rng}
  end

  defp hourly(traffic, day_visitors, rng) do
    shape_total = Enum.reduce(traffic.hour_shape, 0, &(&2 + &1))

    Enum.map_reduce(traffic.hour_shape, rng, fn share, rng ->
      {noise, rng} = Rng.uniform(rng, 0.85, 1.15)
      visitors = day_visitors * share / shape_total * noise
      {visit_ratio, rng} = Rng.uniform(rng, 1.12, 1.2)
      {pages, rng} = Rng.uniform(rng, 3.0, 3.6)
      {bounce, rng} = Rng.uniform(rng, 35, 48)
      {duration, rng} = Rng.uniform(rng, 115, 190)
      {rate, rng} = Rng.uniform(rng, 1.8, 3.6)

      point = %{
        visitors: visitors,
        visits: visitors * visit_ratio,
        pageviews: visitors * pages,
        bounce: bounce,
        duration: duration,
        conversions: visitors * rate / 100
      }

      {point, rng}
    end)
  end
end
