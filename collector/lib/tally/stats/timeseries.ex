defmodule Tally.Stats.Timeseries do
  @moduledoc """
  Metric values per bucket (hour, day, week or month) across a period. Visits are bucketed by
  their start time; buckets with no traffic are present with zeros so charts have a full x axis.
  """

  alias Tally.Stats.Metrics
  alias Tally.Stats.Period

  @type point :: %{
          date: String.t(),
          label: String.t(),
          visitors: number(),
          visits: number(),
          pageviews: number(),
          bounce: number(),
          duration: number(),
          conversions: number()
        }

  @doc """
  One point per bucket of `period`.
  """
  @spec run([Tally.Stats.Visit.t()], Period.t(), [Tally.Stats.Goal.t()]) :: [point()]
  def run(visits, %Period{interval: interval} = period, goals) do
    by_bucket = Enum.group_by(visits, &Period.bucket_start(&1.start, interval))

    for bucket <- Period.buckets(period) do
      bucket_visits = Map.get(by_bucket, bucket, [])

      bucket_visits
      |> Metrics.totals(goals)
      |> Map.merge(%{
        date: DateTime.to_iso8601(bucket),
        label: Period.bucket_label(bucket, interval)
      })
    end
  end
end
