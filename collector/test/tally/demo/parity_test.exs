defmodule Tally.Demo.ParityTest do
  @moduledoc """
  The demo dashboard used to be computed in TypeScript in the Next.js app. This test compares the
  Elixir model with that implementation's output, captured in
  `test/fixtures/reference_dashboard.json`, so the numbers on the demo page are unchanged.
  """
  use ExUnit.Case, async: true

  @reference "test/fixtures/reference_dashboard.json" |> File.read!() |> Jason.decode!()

  # Both implementations use IEEE doubles and the same operation order; only libm's sin can differ
  # in the last bit, so allow a relative error far below anything displayed.
  @tolerance 1.0e-9

  setup_all do
    %{data: Tally.Demo.dashboard().data}
  end

  defp close?(nil, nil), do: true

  defp close?(a, b) when is_number(a) and is_number(b),
    do: abs(a - b) <= @tolerance * max(1, abs(b))

  defp close?(_, _), do: false

  defp assert_point(actual, expected) do
    for {key, value} <- expected do
      assert close?(Map.fetch!(actual, String.to_existing_atom(key)), value),
             "#{key}: #{inspect(actual)} vs #{inspect(expected)}"
    end
  end

  for range <- ~w(today 7d 30d 12m) do
    test "#{range}: chart series, labels and totals", %{data: data} do
      actual = data[unquote(range)]
      expected = @reference["ranges"][unquote(range)]

      assert actual.labels == expected["labels"]
      assert actual.tips == expected["tips"]
      assert actual.span == expected["span"]
      assert actual.interval == expected["interval"]
      assert actual.comparison == expected["comparison"]
      assert length(actual.current) == length(expected["current"])

      for {a, e} <- Enum.zip(actual.current, expected["current"]) do
        if is_nil(e), do: assert(is_nil(a)), else: assert_point(a, e)
      end

      for {a, e} <- Enum.zip(actual.previous, expected["previous"]), do: assert_point(a, e)

      assert_point(actual.totals, expected["totals"])
      assert_point(actual.prior_totals, expected["priorTotals"])
    end

    test "#{range}: KPI deltas", %{data: data} do
      for {metric, expected} <- @reference["deltas"][unquote(range)] do
        delta = data[unquote(range)].deltas[String.to_existing_atom(metric)]
        assert delta.text == expected["text"]
        assert Atom.to_string(delta.direction) == expected["direction"]
        assert delta.good == expected["good"]
      end
    end

    test "#{range}: breakdowns, goals and funnel", %{data: data} do
      actual = data[unquote(range)]

      for {dimension, tabs} <- @reference["breakdowns"][unquote(range)], {tab, rows} <- tabs do
        actual_rows = actual.breakdowns[dimension][tab]
        assert Enum.map(actual_rows, & &1.name) == Enum.map(rows, & &1["name"])
        assert Enum.map(actual_rows, & &1.code) == Enum.map(rows, &Map.get(&1, "code"))

        for {a, e} <- Enum.zip(actual_rows, rows) do
          assert close?(a.value, e["value"]) and close?(a.share, e["share"]) and
                   close?(a.width, e["width"])
        end
      end

      for {a, e} <- Enum.zip(actual.goals, @reference["goals"][unquote(range)]) do
        assert a.name == e["name"]
        assert close?(a.uniques, e["uniques"])
        assert close?(a.total, e["total"])
        assert close?(a.conversion_rate, e["conversionRate"])
        assert close?(a.revenue, e["revenue"])
      end

      for {a, e} <- Enum.zip(actual.funnel, @reference["funnel"][unquote(range)]) do
        assert a.name == e["name"]
        assert close?(a.value, e["value"])
        assert close?(a.of_first, e["ofFirst"])
        assert close?(a.drop_off, e["dropOff"])
      end
    end
  end
end
