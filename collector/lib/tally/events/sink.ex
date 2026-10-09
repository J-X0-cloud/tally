defmodule Tally.Events.Sink do
  @moduledoc """
  Where buffered events go. `Tally.Events.Buffer` hands each flushed batch to every configured sink.
  A sink must not raise for a well-formed batch; failures are logged by the buffer and the batch is
  still offered to the remaining sinks.
  """

  alias Tally.Events.Event

  @callback write_batch([Event.t()]) :: :ok | {:error, term()}
end
