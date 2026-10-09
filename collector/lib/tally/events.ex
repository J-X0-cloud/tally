defmodule Tally.Events do
  @moduledoc """
  Entry point for recording events produced by `Tally.Ingest`.
  """

  alias Tally.Events.Buffer
  alias Tally.Events.Event

  @doc """
  Records an accepted event: it is buffered for the sinks.
  """
  @spec record(Event.t()) :: :ok
  def record(%Event{} = event) do
    Buffer.push(event)
  end
end
