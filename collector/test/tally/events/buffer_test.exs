defmodule Tally.Events.BufferTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  import Tally.Factory

  alias Tally.Events.Buffer

  defp start_buffer(opts) do
    test = self()
    sink = fn batch -> send(test, {:batch, Enum.map(batch, & &1.path)}) && :ok end
    name = :"buffer_#{System.unique_integer([:positive])}"
    opts = Keyword.merge([name: name, sinks: [sink], max_batch: 3, max_wait_ms: 60_000], opts)
    pid = start_supervised!({Buffer, opts})
    %{buffer: name, pid: pid}
  end

  test "flushes when the batch is full, in arrival order" do
    %{buffer: buffer} = start_buffer([])

    for path <- ["/a", "/b", "/c", "/d"], do: Buffer.push(buffer, pageview(path))

    assert_receive {:batch, ["/a", "/b", "/c"]}
    assert Buffer.pending(buffer) == 1
  end

  test "flushes after max_wait_ms" do
    %{buffer: buffer} = start_buffer(max_wait_ms: 20)
    Buffer.push(buffer, pageview("/a"))

    assert_receive {:batch, ["/a"]}, 500
    assert Buffer.pending(buffer) == 0
  end

  test "flush/1 drains synchronously and skips empty batches" do
    %{buffer: buffer} = start_buffer([])
    assert Buffer.flush(buffer) == 0
    refute_received {:batch, _}

    Buffer.push(buffer, pageview("/a"))
    assert Buffer.flush(buffer) == 1
    assert_received {:batch, ["/a"]}
  end

  test "a failing sink doesn't stop the others" do
    test = self()
    failing = fn _batch -> raise "disk full" end
    rejecting = fn _batch -> {:error, :unavailable} end
    working = fn batch -> send(test, {:ok, length(batch)}) && :ok end
    %{buffer: buffer} = start_buffer(sinks: [failing, rejecting, working])

    log =
      capture_log(fn ->
        Buffer.push(buffer, pageview("/a"))
        Buffer.flush(buffer)
      end)

    assert_received {:ok, 1}
    assert log =~ "disk full"
    assert log =~ "rejected a batch: :unavailable"
  end

  test "pending events are flushed on shutdown" do
    %{buffer: buffer} = start_buffer([])
    Buffer.push(buffer, pageview("/last"))
    Buffer.pending(buffer)

    stop_supervised!(Buffer)
    assert_received {:batch, ["/last"]}
  end
end
