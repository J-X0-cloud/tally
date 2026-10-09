defmodule Tally.Events.Store do
  @moduledoc """
  In-memory event store used by the stats queries.

  Events are kept in an `:ordered_set` ETS table keyed by `{site, unix_microseconds, sequence}`, so a
  site's events for a time range are one contiguous key range and come back in time order. The
  table is public for reads; writes are serialised through this process, which also prunes events
  older than the retention window once an hour.

  Being in memory, the store holds what this instance has received since it started. The NDJSON
  `Tally.Events.LogSink` output is the durable record.
  """
  use GenServer

  @behaviour Tally.Events.Sink

  alias Tally.Events.Event

  @table __MODULE__

  @doc false
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl Tally.Events.Sink
  def write_batch(events) when is_list(events), do: GenServer.call(__MODULE__, {:insert, events})

  @doc """
  Inserts events directly (seeding and tests).
  """
  @spec insert_all([Event.t()]) :: :ok
  def insert_all(events), do: write_batch(events)

  @doc """
  A site's events with `from <= timestamp < to`, oldest first.
  """
  @spec events(String.t(), DateTime.t(), DateTime.t()) :: [Event.t()]
  def events(site, %DateTime{} = from, %DateTime{} = to) do
    from_us = DateTime.to_unix(from, :microsecond)
    to_us = DateTime.to_unix(to, :microsecond)

    match_spec = [
      {{{site, :"$1", :_}, :"$2"}, [{:>=, :"$1", from_us}, {:<, :"$1", to_us}], [:"$2"]}
    ]

    :ets.select(@table, match_spec)
  end

  @doc """
  Number of stored events for a site.
  """
  @spec count(String.t()) :: non_neg_integer()
  def count(site) do
    :ets.select_count(@table, [{{{site, :_, :_}, :_}, [], [true]}])
  end

  @doc """
  Deletes every event older than `cutoff`. Returns the number deleted.
  """
  @spec prune(DateTime.t()) :: non_neg_integer()
  def prune(%DateTime{} = cutoff), do: GenServer.call(__MODULE__, {:prune, cutoff})

  @doc """
  Deletes everything (tests).
  """
  @spec clear() :: :ok
  def clear, do: GenServer.call(__MODULE__, :clear)

  # -- server -------------------------------------------------------------------------------------

  @impl GenServer
  def init(_opts) do
    :ets.new(@table, [:ordered_set, :protected, :named_table, read_concurrency: true])
    schedule_prune()
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:insert, events}, _from, state) do
    rows =
      Enum.map(events, &{{&1.site, Event.unix_us(&1), System.unique_integer([:monotonic])}, &1})

    :ets.insert(@table, rows)
    {:reply, :ok, state}
  end

  def handle_call({:prune, cutoff}, _from, state) do
    {:reply, delete_before(cutoff), state}
  end

  def handle_call(:clear, _from, state) do
    :ets.delete_all_objects(@table)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:prune, state) do
    retention_days = Keyword.get(config(), :retention_days, 400)
    delete_before(DateTime.add(DateTime.utc_now(), -retention_days, :day))
    schedule_prune()
    {:noreply, state}
  end

  defp delete_before(cutoff) do
    cutoff_us = DateTime.to_unix(cutoff, :microsecond)
    :ets.select_delete(@table, [{{{:_, :"$1", :_}, :_}, [{:<, :"$1", cutoff_us}], [true]}])
  end

  defp schedule_prune do
    Process.send_after(self(), :prune, Keyword.get(config(), :prune_interval_ms, :timer.hours(1)))
  end

  defp config, do: Application.get_env(:tally, __MODULE__, [])
end
