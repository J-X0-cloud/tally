defmodule Tally.Stats.DeltaTest do
  use ExUnit.Case, async: true

  alias Tally.Stats.Delta

  doctest Delta

  test "small changes keep one decimal, large ones are rounded" do
    assert Delta.new(104.26, 100).text == "4.3%"
    assert Delta.new(112.5, 100).text == "13%"
    assert Delta.new(150, 100).text == "50%"
  end

  test "direction and goodness" do
    assert %Delta{direction: :down, good: false} = Delta.new(90, 100)
    assert %Delta{direction: :up, good: false} = Delta.new(45, 40, true)
    assert %Delta{direction: :down, good: true} = Delta.new(35, 40, true)
  end

  test "no prior value means no change" do
    assert %Delta{text: "0.0%", direction: :down, good: false, change: +0.0} = Delta.new(10, 0)
  end

  test "encodes to JSON" do
    assert Jason.encode!(Delta.new(110, 100)) =~ ~s("direction":"up")
  end
end
