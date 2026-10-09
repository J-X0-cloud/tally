defmodule Tally.Billing.RateLimiterTest do
  use ExUnit.Case, async: true

  alias Tally.Billing.RateLimiter

  defp bucket, do: "bucket-#{System.unique_integer([:positive])}"

  test "allows up to the limit within a window, then denies" do
    b = bucket()
    now = 1_790_000_000

    assert {:allow, %{remaining: 2, limit: 3}} = RateLimiter.hit(b, 3, now)
    assert {:allow, %{remaining: 1}} = RateLimiter.hit(b, 3, now + 10)
    assert {:allow, %{remaining: 0}} = RateLimiter.hit(b, 3, now + 20)
    assert {:deny, %{remaining: 0, reset: reset}} = RateLimiter.hit(b, 3, now + 30)
    assert reset == (div(now, 3600) + 1) * 3600
  end

  test "a new window starts a new count" do
    b = bucket()
    now = 1_790_000_000
    RateLimiter.hit(b, 1, now)
    assert {:deny, _} = RateLimiter.hit(b, 1, now)
    assert {:allow, _} = RateLimiter.hit(b, 1, now + 3600)
  end

  test "buckets are independent and counts are exact under concurrency" do
    b = bucket()

    results =
      1..200
      |> Task.async_stream(fn _ -> RateLimiter.hit(b, 150, 1_790_000_000) end)
      |> Enum.map(fn {:ok, {decision, _}} -> decision end)

    assert Enum.count(results, &(&1 == :allow)) == 150
    assert {:allow, _} = RateLimiter.hit(bucket(), 1, 1_790_000_000)
  end
end
