defmodule Tally.Events.LogSinkTest do
  use ExUnit.Case, async: true

  import Tally.Factory

  alias Tally.Events.LogSink

  test "writes one JSON object per line" do
    {:ok, device} = StringIO.open("")

    events = [
      pageview("/a"),
      custom("Purchase",
        revenue: %{amount: 64.0, currency: "USD"},
        props: %{"collection" => "fall-glaze"}
      )
    ]

    assert LogSink.write_batch(events, device) == :ok
    {_, output} = StringIO.contents(device)
    lines = String.split(output, "\n", trim: true)

    assert length(lines) == 2
    assert [%{"path" => "/a", "name" => "pageview"}, purchase] = Enum.map(lines, &Jason.decode!/1)
    assert purchase["revenue"] == %{"amount" => 64.0, "currency" => "USD"}
    assert purchase["props"] == %{"collection" => "fall-glaze"}
    assert purchase["timestamp"] == "2026-09-25T10:00:00Z"
  end

  test "an empty batch writes nothing" do
    {:ok, device} = StringIO.open("")
    LogSink.write_batch([], device)
    assert StringIO.contents(device) == {"", ""}
  end
end
