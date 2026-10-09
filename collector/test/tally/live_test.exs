defmodule Tally.LiveTest do
  use ExUnit.Case, async: false

  import Tally.Factory

  alias Tally.Live

  setup do
    Live.reset()
    on_exit(&Live.reset/0)
    :ok
  end

  defp now_event(attrs) do
    attrs |> Keyword.put(:at, DateTime.utc_now() |> DateTime.truncate(:second)) |> event()
  end

  defp settle, do: :sys.get_state(Live)

  test "counts each visitor once and broadcasts visits and counts" do
    :ok = Live.subscribe("harrowfield.co")

    Live.touch(now_event(visitor_id: "a", path: "/"))
    Live.touch(now_event(visitor_id: "a", path: "/shop/mugs"))
    Live.touch(now_event(visitor_id: "b", path: "/cart", source: "Instagram"))
    settle()

    assert Live.count("harrowfield.co") == 2
    assert Live.count("example.org") == 0

    assert_received {:live_visit, "harrowfield.co", %{path: "/"}}
    assert_received {:live_count, "harrowfield.co", 1}
    assert_received {:live_visit, "harrowfield.co", %{path: "/shop/mugs"}}
    assert_received {:live_count, "harrowfield.co", 2}
    # the second event from visitor a doesn't change the count, so there is no extra count message
    refute_received {:live_count, "harrowfield.co", 1}
  end

  test "snapshot/1 shows current pages, sources and the recent feed" do
    Live.touch(now_event(visitor_id: "a", path: "/"))
    Live.touch(now_event(visitor_id: "a", path: "/shop/mugs"))
    Live.touch(now_event(visitor_id: "b", path: "/shop/mugs", source: "Instagram", country: "CA"))
    Live.touch(now_event(visitor_id: "c", path: "/", country: nil))
    settle()

    snapshot = Live.snapshot("harrowfield.co")

    assert snapshot.visitors == 3

    assert snapshot.pages == [%{name: "/shop/mugs", visitors: 2}, %{name: "/", visitors: 1}]

    assert [%{name: "Google", visitors: 2}, %{name: "Instagram", visitors: 1}] = snapshot.sources
    assert %{name: "Unknown", visitors: 1} in snapshot.countries
    assert length(snapshot.feed) == 4
    assert hd(snapshot.feed).path == "/"
  end

  test "visitors expire after the window" do
    :ok = Live.subscribe("harrowfield.co")
    old = DateTime.add(DateTime.utc_now(), -301, :second)

    Live.touch(event(visitor_id: "gone", at: old))
    Live.touch(now_event(visitor_id: "here"))
    settle()
    assert Live.count("harrowfield.co") == 1

    Live.sweep()
    assert Live.snapshot("harrowfield.co").feed |> Enum.map(& &1.path) == ["/"]
    assert Live.count("harrowfield.co") == 1
  end

  test "the sweep broadcasts when a site goes quiet" do
    :ok = Live.subscribe("example.org")
    almost_gone = DateTime.add(DateTime.utc_now(), -299, :second)

    Live.touch(event(site: "example.org", visitor_id: "a", at: almost_gone))
    settle()
    assert_received {:live_count, "example.org", 1}

    Application.put_env(:tally, Live, window_seconds: 1, sweep_interval_ms: 5_000)

    on_exit(fn ->
      Application.put_env(:tally, Live, window_seconds: 300, sweep_interval_ms: 5_000)
    end)

    Live.sweep()
    assert_received {:live_count, "example.org", 0}
    assert Live.snapshot("example.org").feed == []
  end
end
