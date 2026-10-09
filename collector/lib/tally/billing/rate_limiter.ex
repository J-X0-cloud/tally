defmodule Tally.Billing.RateLimiter do
  @moduledoc """
  Fixed-window request counting for the Stats API: each key gets its plan's requests per hour.

  Counters live in a public ETS table and are bumped with `:ets.update_counter/4`, so concurrent
  requests never lose a count. The owning process deletes counters from past windows every few
  minutes.
  """
  use GenServer

  @table __MODULE__
  @window_seconds 3600

  @type decision ::
          {:allow, %{limit: pos_integer(), remaining: non_neg_integer(), reset: integer()}}
          | {:deny, %{limit: pos_integer(), remaining: 0, reset: integer()}}

  @doc false
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc """
  Counts one request for `bucket` against `limit` requests per hour. `reset` is the Unix time the
  window ends.
  """
  @spec hit(String.t(), pos_integer(), integer()) :: decision()
  def hit(bucket, limit, now \\ System.system_time(:second)) do
    window = div(now, @window_seconds)
    reset = (window + 1) * @window_seconds
    count = :ets.update_counter(@table, {bucket, window}, {2, 1}, {{bucket, window}, 0})

    if count <= limit do
      {:allow, %{limit: limit, remaining: limit - count, reset: reset}}
    else
      {:deny, %{limit: limit, remaining: 0, reset: reset}}
    end
  end

  @doc "Deletes every counter (tests)."
  @spec reset() :: :ok
  def reset do
    :ets.delete_all_objects(@table)
    :ok
  end

  @impl true
  def init(_opts) do
    :ets.new(@table, [:set, :public, :named_table, write_concurrency: true])
    schedule_cleanup()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    current = div(System.system_time(:second), @window_seconds)
    :ets.select_delete(@table, [{{{:_, :"$1"}, :_}, [{:<, :"$1", current}], [true]}])
    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup, do: Process.send_after(self(), :cleanup, :timer.minutes(5))
end
