defmodule Tally.Stats.Period do
  @moduledoc """
  A reporting period: a half-open UTC time range `[from, to)` plus the bucket interval used for
  timeseries.

  | key      | range                                  | interval |
  | -------- | -------------------------------------- | -------- |
  | `day`    | today                                  | hour     |
  | `7d`     | the last 7 days, including today       | day      |
  | `30d`    | the last 30 days, including today      | day      |
  | `month`  | the current month to date              | day      |
  | `6mo`    | the last 6 calendar months             | month    |
  | `12mo`   | the last 12 calendar months            | month    |
  | `custom` | `from`..`to` dates, inclusive          | day/week |

  Periods are anchored on a `today` date (default: the current UTC date) so reports are reproducible.
  """

  @enforce_keys [:key, :from, :to, :interval]
  defstruct [:key, :from, :to, :interval]

  @type interval :: :hour | :day | :week | :month
  @type t :: %__MODULE__{
          key: String.t(),
          from: DateTime.t(),
          to: DateTime.t(),
          interval: interval()
        }

  @keys ~w(day 7d 30d month 6mo 12mo custom)
  @max_custom_days 400

  @doc "Every supported period key."
  def keys, do: @keys

  @doc """
  Builds a period.

  Options: `:today` (a `Date` anchor), and `:from` / `:to` (ISO dates) for `custom`.
  """
  @spec new(String.t(), keyword()) :: {:ok, t()} | {:error, {:invalid, String.t(), String.t()}}
  def new(key, opts \\ []) do
    today = Keyword.get_lazy(opts, :today, &Date.utc_today/0)

    case key do
      "day" -> {:ok, days(key, today, today, :hour)}
      "7d" -> {:ok, days(key, Date.add(today, -6), today, :day)}
      "30d" -> {:ok, days(key, Date.add(today, -29), today, :day)}
      "month" -> {:ok, days(key, Date.beginning_of_month(today), today, :day)}
      "6mo" -> {:ok, months(key, today, 6)}
      "12mo" -> {:ok, months(key, today, 12)}
      "custom" -> custom(Keyword.get(opts, :from), Keyword.get(opts, :to))
      _ -> {:error, {:invalid, "period", "must be one of: #{Enum.join(@keys, ", ")}"}}
    end
  end

  @doc """
  The period of the same length immediately before this one, for comparisons. Month-based periods
  shift by whole months.
  """
  @spec previous(t()) :: t()
  def previous(%__MODULE__{key: key, from: from} = period) when key in ["6mo", "12mo"] do
    months = if key == "6mo", do: 6, else: 12
    start = from |> DateTime.to_date() |> shift_months(-months)
    %{period | from: midnight(start), to: from}
  end

  def previous(%__MODULE__{key: "month", from: from, to: to} = period) do
    start = from |> DateTime.to_date() |> shift_months(-1)
    length_days = DateTime.diff(to, from, :day)

    end_date =
      Date.add(start, length_days) |> min_date(Date.beginning_of_month(DateTime.to_date(from)))

    %{period | from: midnight(start), to: midnight(end_date)}
  end

  def previous(%__MODULE__{from: from, to: to} = period) do
    seconds = DateTime.diff(to, from, :second)
    %{period | from: DateTime.add(from, -seconds, :second), to: from}
  end

  @doc """
  The start of every bucket in the period, oldest first.
  """
  @spec buckets(t()) :: [DateTime.t()]
  def buckets(%__MODULE__{from: from, to: to, interval: interval}) do
    from
    |> bucket_start(interval)
    |> Stream.iterate(&next_bucket(&1, interval))
    |> Enum.take_while(&(DateTime.compare(&1, to) == :lt))
  end

  @doc """
  The bucket a timestamp falls into.
  """
  @spec bucket_start(DateTime.t(), interval()) :: DateTime.t()
  def bucket_start(%DateTime{} = ts, :hour), do: %{ts | minute: 0, second: 0, microsecond: {0, 0}}
  def bucket_start(%DateTime{} = ts, :day), do: ts |> DateTime.to_date() |> midnight()

  def bucket_start(%DateTime{} = ts, :week),
    do: ts |> DateTime.to_date() |> Date.beginning_of_week(:monday) |> midnight()

  def bucket_start(%DateTime{} = ts, :month),
    do: ts |> DateTime.to_date() |> Date.beginning_of_month() |> midnight()

  @doc """
  A short label for a bucket: `14:00`, `Sep 25`, `Week of Sep 22`, `Sep 2026`.
  """
  @spec bucket_label(DateTime.t(), interval()) :: String.t()
  def bucket_label(ts, :hour), do: Calendar.strftime(ts, "%H:00")
  def bucket_label(ts, :day), do: Calendar.strftime(ts, "%b %-d")
  def bucket_label(ts, :week), do: Calendar.strftime(ts, "Week of %b %-d")
  def bucket_label(ts, :month), do: Calendar.strftime(ts, "%b %Y")

  @doc "Whether a timestamp is inside the period."
  @spec contains?(t(), DateTime.t()) :: boolean()
  def contains?(%__MODULE__{from: from, to: to}, ts) do
    DateTime.compare(ts, from) != :lt and DateTime.compare(ts, to) == :lt
  end

  @doc "The period as a JSON-friendly map."
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = period) do
    %{
      key: period.key,
      from: DateTime.to_iso8601(period.from),
      to: DateTime.to_iso8601(period.to),
      interval: period.interval
    }
  end

  defp days(key, first, last, interval) do
    %__MODULE__{
      key: key,
      from: midnight(first),
      to: midnight(Date.add(last, 1)),
      interval: interval
    }
  end

  defp months(key, today, count) do
    first = today |> Date.beginning_of_month() |> shift_months(-(count - 1))

    %__MODULE__{
      key: key,
      from: midnight(first),
      to: midnight(Date.add(today, 1)),
      interval: :month
    }
  end

  defp custom(from, to) when is_binary(from) and is_binary(to) do
    with {:ok, first} <- parse_date("from", from),
         {:ok, last} <- parse_date("to", to) do
      span = Date.diff(last, first) + 1

      cond do
        span < 1 -> {:error, {:invalid, "to", "must not be before from"}}
        span > @max_custom_days -> {:error, {:invalid, "to", "range is limited to 400 days"}}
        true -> {:ok, days("custom", first, last, if(span <= 62, do: :day, else: :week))}
      end
    end
  end

  defp custom(_, _), do: {:error, {:invalid, "period", "custom needs from and to dates"}}

  defp parse_date(field, value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> {:ok, date}
      {:error, _} -> {:error, {:invalid, field, "must be a date like 2026-09-25"}}
    end
  end

  defp next_bucket(ts, :hour), do: DateTime.add(ts, 1, :hour)
  defp next_bucket(ts, :day), do: DateTime.add(ts, 1, :day)
  defp next_bucket(ts, :week), do: DateTime.add(ts, 7, :day)
  defp next_bucket(ts, :month), do: ts |> DateTime.to_date() |> shift_months(1) |> midnight()

  @doc false
  def shift_months(%Date{year: year, month: month}, delta) do
    index = year * 12 + month - 1 + delta
    Date.new!(div(index, 12), rem(index, 12) + 1, 1)
  end

  defp min_date(a, b), do: if(Date.compare(a, b) == :gt, do: b, else: a)

  defp midnight(date), do: DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
end
