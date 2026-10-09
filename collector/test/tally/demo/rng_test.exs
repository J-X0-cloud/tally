defmodule Tally.Demo.RngTest do
  use ExUnit.Case, async: true

  alias Tally.Demo.Rng

  doctest Rng

  # Reference values from the JavaScript mulberry32 / FNV-1a implementation the demo was built with.
  test "matches the reference sequence for a seed" do
    rng = Rng.new(11)
    {a, rng} = Rng.next(rng)
    {b, rng} = Rng.next(rng)
    {c, _rng} = Rng.next(rng)

    assert [a, b, c] == [0.5115870486479253, 0.5299464082345366, 0.6081185641232878]
  end

  test "uniform/3 scales into the range" do
    assert {16.011037519201636, _} = Rng.uniform(Rng.new(42), 10, 20)
  end

  test "seeds are truncated to 32 bits" do
    assert {0.9236361971125007, _} = Rng.next(Rng.new(0xFFFFFFFF + 5))
  end

  test "hash_seed/1 is FNV-1a over UTF-16 code units" do
    assert Rng.hash_seed("sources/channels/30d") == 472_563_128
    assert Rng.hash_seed("a") == 3_826_002_220
    assert Rng.hash_seed("café") == 856_211_068
  end

  test "draws stay in [0, 1)" do
    {values, _} = Enum.map_reduce(1..10_000, Rng.new(7), fn _, rng -> Rng.next(rng) end)
    assert Enum.all?(values, &(&1 >= 0 and &1 < 1))
    assert_in_delta Enum.sum(values) / 10_000, 0.5, 0.02
  end
end
