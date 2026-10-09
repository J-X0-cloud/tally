defmodule Tally.Stats.PeriodTest do
  use ExUnit.Case, async: true

  alias Tally.Stats.Period

  @today ~D[2026-09-25]

  defp period(key, opts \\ []) do
    {:ok, period} = Period.new(key, Keyword.put(opts, :today, @today))
    period
  end

  test "day is today, hourly" do
    p = period("day")

    assert {p.from, p.to, p.interval} ==
             {~U[2026-09-25 00:00:00Z], ~U[2026-09-26 00:00:00Z], :hour}

    assert length(Period.buckets(p)) == 24
    assert p |> Period.buckets() |> hd() |> Period.bucket_label(:hour) == "00:00"
  end

  test "7d and 30d include today" do
    assert period("7d").from == ~U[2026-09-19 00:00:00Z]
    assert length(Period.buckets(period("7d"))) == 7
    assert period("30d").from == ~U[2026-08-27 00:00:00Z]
    assert length(Period.buckets(period("30d"))) == 30
  end

  test "month is month to date" do
    p = period("month")
    assert p.from == ~U[2026-09-01 00:00:00Z]
    assert length(Period.buckets(p)) == 25
  end

  test "6mo and 12mo are calendar months" do
    p = period("12mo")
    assert p.from == ~U[2025-10-01 00:00:00Z]
    assert p.interval == :month
    labels = p |> Period.buckets() |> Enum.map(&Period.bucket_label(&1, :month))
    assert hd(labels) == "Oct 2025"
    assert List.last(labels) == "Sep 2026"
    assert length(labels) == 12

    assert period("6mo").from == ~U[2026-04-01 00:00:00Z]
  end

  test "custom ranges are inclusive and pick an interval by length" do
    p = period("custom", from: "2026-09-01", to: "2026-09-10")

    assert {p.from, p.to, p.interval} ==
             {~U[2026-09-01 00:00:00Z], ~U[2026-09-11 00:00:00Z], :day}

    long = period("custom", from: "2026-01-01", to: "2026-09-10")
    assert long.interval == :week
    assert long |> Period.buckets() |> hd() == ~U[2025-12-29 00:00:00Z]
  end

  test "custom ranges are validated" do
    assert {:error, {:invalid, "to", _}} =
             Period.new("custom", from: "2026-09-10", to: "2026-09-01")

    assert {:error, {:invalid, "to", _}} =
             Period.new("custom", from: "2024-01-01", to: "2026-01-01")

    assert {:error, {:invalid, "from", _}} =
             Period.new("custom", from: "yesterday", to: "2026-01-01")

    assert {:error, {:invalid, "period", _}} = Period.new("custom")
    assert {:error, {:invalid, "period", _}} = Period.new("fortnight")
  end

  test "previous/1 has the same length immediately before" do
    prev = period("7d") |> Period.previous()
    assert {prev.from, prev.to} == {~U[2026-09-12 00:00:00Z], ~U[2026-09-19 00:00:00Z]}

    prev_day = period("day") |> Period.previous()
    assert prev_day.from == ~U[2026-09-24 00:00:00Z]
  end

  test "previous/1 shifts month periods by whole months" do
    prev = period("month") |> Period.previous()
    assert {prev.from, prev.to} == {~U[2026-08-01 00:00:00Z], ~U[2026-08-26 00:00:00Z]}

    prev_year = period("12mo") |> Period.previous()
    assert {prev_year.from, prev_year.to} == {~U[2024-10-01 00:00:00Z], ~U[2025-10-01 00:00:00Z]}
  end

  test "bucket_start/2 and labels" do
    ts = ~U[2026-09-25 14:40:12Z]
    assert Period.bucket_start(ts, :hour) == ~U[2026-09-25 14:00:00Z]
    assert Period.bucket_start(ts, :day) == ~U[2026-09-25 00:00:00Z]
    assert Period.bucket_start(ts, :week) == ~U[2026-09-21 00:00:00Z]
    assert Period.bucket_start(ts, :month) == ~U[2026-09-01 00:00:00Z]
    assert Period.bucket_label(~U[2026-09-21 00:00:00Z], :week) == "Week of Sep 21"
    assert Period.bucket_label(~U[2026-09-05 00:00:00Z], :day) == "Sep 5"
  end

  test "contains?/2 is half-open" do
    p = period("day")
    assert Period.contains?(p, ~U[2026-09-25 00:00:00Z])
    refute Period.contains?(p, ~U[2026-09-26 00:00:00Z])
  end

  test "shift_months/2 crosses years" do
    assert Period.shift_months(~D[2026-01-15], -1) == ~D[2025-12-01]
    assert Period.shift_months(~D[2025-12-01], 1) == ~D[2026-01-01]
  end
end
