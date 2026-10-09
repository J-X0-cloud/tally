defmodule Tally.Events.Buffer do
  @moduledoc """
  Buffers incoming events and flushes them to the configured sinks in batches.

  A batch is flushed when it reaches `:max_batch` events, or `:max_wait_ms` after the first event of
  the batch arrived, whichever comes first. Sinks are modules implementing `Tally.Events.Sink` or
  one-argument functions. The buffer traps exits so a normal shutdown flushes what
  is still pending.
  """
  use GenServer

  require Logger

  alias Tally.Events.Event

  @doc false
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Adds an event to the current batch.
  """
  @spec push(GenServer.server(), Event.t()) :: :ok
  def push(server \\ __MODULE__, %Event{} = event), do: GenServer.cast(server, {:push, event})

  @doc """
  Flushes the current batch synchronously. Returns the number of events flushed.
  """
  @spec flush(GenServer.server()) :: non_neg_integer()
  def flush(server \\ __MODULE__), do: GenServer.call(server, :flush)

  @doc """
  Number of events waiting to be flushed.
  """
  @spec pending(GenServer.server()) :: non_neg_integer()
  def pending(server \\ __MODULE__), do: GenServer.call(server, :pending)

  # -- server -------------------------------------------------------------------------------------

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    config = Keyword.merge(Application.get_env(:tally, __MODULE__, []), opts)

    {:ok,
     %{
       events: [],
       size: 0,
       timer: nil,
       max_batch: Keyword.get(config, :max_batch, 500),
       max_wait_ms: Keyword.get(config, :max_wait_ms, 2_000),
       sinks: Keyword.get(config, :sinks, [])
     }}
  end

  @impl true
  def handle_cast({:push, event}, state) do
    state = %{state | events: [event | state.events], size: state.size + 1}

    cond do
      state.size >= state.max_batch -> {:noreply, drain(state)}
      state.timer == nil -> {:noreply, %{state | timer: start_timer(state.max_wait_ms)}}
      true -> {:noreply, state}
    end
  end

  @impl true
  def handle_call(:flush, _from, state), do: {:reply, state.size, drain(state)}
  def handle_call(:pending, _from, state), do: {:reply, state.size, state}

  @impl true
  def handle_info({:timeout, timer, :flush}, %{timer: timer} = state),
    do: {:noreply, drain(state)}

  # A timer that fired after a size-triggered flush already cancelled it.
  def handle_info({:timeout, _stale, :flush}, state), do: {:noreply, state}

  @impl true
  def terminate(_reason, state) do
    drain(state)
    :ok
  end

  defp drain(%{size: 0} = state), do: cancel_timer(state)

  defp drain(state) do
    batch = Enum.reverse(state.events)

    for sink <- state.sinks do
      try do
        case deliver(sink, batch) do
          :ok ->
            :ok

          {:error, reason} ->
            Logger.error("#{inspect(sink)} rejected a batch: #{inspect(reason)}")
        end
      catch
        kind, reason ->
          Logger.error(
            "#{inspect(sink)} failed: " <> Exception.format(kind, reason, __STACKTRACE__)
          )
      end
    end

    cancel_timer(%{state | events: [], size: 0})
  end

  # A sink is a module implementing Tally.Events.Sink, or a one-argument function.
  defp deliver(sink, batch) when is_function(sink, 1), do: sink.(batch)
  defp deliver(sink, batch) when is_atom(sink), do: sink.write_batch(batch)

  defp start_timer(ms), do: :erlang.start_timer(ms, self(), :flush)

  defp cancel_timer(%{timer: nil} = state), do: state

  defp cancel_timer(%{timer: timer} = state) do
    :erlang.cancel_timer(timer)
    %{state | timer: nil}
  end
end
