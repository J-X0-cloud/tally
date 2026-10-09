defmodule Tally.Demo.SimulationTest do
  use ExUnit.Case, async: true

  alias Tally.Demo.Fixture
  alias Tally.Demo.Simulation

  setup_all do
    %{sim: Simulation.run()}
  end

  test "760 days ending yesterday", %{sim: sim} do
    assert length(sim.days) == 760
    assert hd(sim.days).date == ~D[2024-08-26]
    assert List.last(sim.days).date == ~D[2026-09-24]
  end

  test "today's hours run up to the snapshot hour; yesterday has all 24", %{sim: sim} do
    assert length(sim.today_hours) == Fixture.snapshot().hour + 1
    assert length(sim.yesterday_hours) == 24
  end

  test "the first day matches the reference model", %{sim: sim} do
    point = hd(sim.days).point
    assert point.visitors == 480.07970104405297
    assert point.visits == 569.9008121270833
    assert point.pageviews == 1638.2292947380934
    assert point.bounce == 43.806213568896055
    assert point.duration == 153.82507027685642
    assert point.conversions == 13.669341530186038
  end

  test "values stay within the model's ratios", %{sim: sim} do
    for %{point: p} <- sim.days do
      assert p.visits / p.visitors >= 1.15 and p.visits / p.visitors < 1.22
      assert p.pageviews / p.visits >= 2.55 and p.pageviews / p.visits < 3.1
      assert p.bounce >= 34 and p.bounce < 45
      assert p.duration >= 128 and p.duration < 176
    end
  end

  test "traffic grows over the two years", %{sim: sim} do
    first_month = sim.days |> Enum.take(30) |> Enum.map(& &1.point.visitors) |> Enum.sum()
    last_month = sim.days |> Enum.take(-30) |> Enum.map(& &1.point.visitors) |> Enum.sum()
    assert last_month > 2.5 * first_month
  end

  test "spike days stand out", %{sim: sim} do
    by_date = Map.new(sim.days, &{&1.date, &1.point.visitors})
    assert by_date[~D[2025-11-28]] > 1.8 * by_date[~D[2025-11-21]]
  end

  test "weekends are quieter" do
    traffic = Fixture.traffic()

    assert Simulation.weekday(traffic, ~D[2026-09-26]) <
             Simulation.weekday(traffic, ~D[2026-09-22])
  end

  test "the model is deterministic" do
    assert Simulation.run() == Simulation.run()
  end
end
