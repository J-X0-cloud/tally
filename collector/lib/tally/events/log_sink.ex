defmodule Tally.Events.LogSink do
  @moduledoc """
  Writes each batch as NDJSON to standard output, one event per line, where a platform log drain can
  ship it to long-term storage. Lines carry no personal data (see `Tally.Events.Event`).
  """
  @behaviour Tally.Events.Sink

  alias Tally.Events.Event

  @impl true
  def write_batch(events), do: write_batch(events, :stdio)

  @doc """
  Writes the batch to `device`. Exposed with a device argument for tests.
  """
  @spec write_batch([Event.t()], IO.device()) :: :ok
  def write_batch([], _device), do: :ok

  def write_batch(events, device) do
    IO.binwrite(device, encode(events))
  end

  @doc """
  The NDJSON encoding of a batch, with a trailing newline.
  """
  @spec encode([Event.t()]) :: iodata()
  def encode(events) do
    Enum.map(events, &[Jason.encode_to_iodata!(&1), ?\n])
  end
end
