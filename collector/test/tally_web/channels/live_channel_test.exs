defmodule TallyWeb.LiveChannelTest do
  use TallyWeb.ChannelCase, async: false

  alias Tally.Live
  alias TallyWeb.LiveSocket

  setup do
    Live.reset()
    on_exit(&Live.reset/0)
    :ok
  end

  defp connected do
    {:ok, socket} = connect(LiveSocket, %{"token" => "test-growth"})
    socket
  end

  test "rejects connections without a valid key" do
    assert connect(LiveSocket, %{}) == {:error, :unauthorized}
    assert connect(LiveSocket, %{"token" => "nope"}) == {:error, :unauthorized}
  end

  test "rejects unknown sites" do
    assert {:error, %{reason: "unknown site"}} =
             subscribe_and_join(connected(), "live:unknown.example", %{})
  end

  test "pushes a snapshot and presence on join, then visits and counts" do
    Live.touch(event(visitor_id: "a", at: DateTime.utc_now()))
    :sys.get_state(Live)

    {:ok, _reply, socket} = subscribe_and_join(connected(), "live:harrowfield.co", %{})

    assert_push "presence_state", presence
    assert map_size(presence) == 1
    assert_push "snapshot", %{visitors: 1, site: "harrowfield.co"}

    Live.touch(event(visitor_id: "b", path: "/cart", at: DateTime.utc_now()))
    assert_push "visit", %{path: "/cart", at: at}
    assert is_binary(at)
    assert_push "count", %{visitors: 2}

    ref = push(socket, "snapshot", %{})
    assert_reply ref, :ok, %{visitors: 2}
  end
end
