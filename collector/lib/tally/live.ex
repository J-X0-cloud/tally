defmodule Tally.Live do
  @moduledoc """
  Live visitors: everyone with an event in the last few minutes (five by default).

  Each accepted event refreshes its visitor's entry. A sweep every few seconds drops visitors whose
  last event is older than the window. Changes are broadcast on `Tally.PubSub`, topic
  `"live:" <> site`, as:

    * `{:live_visit, site, visit}` for every event (path, source, country, event name, time);
    * `{:live_count, site, count}` when the number of live visitors changes.

  Entries live in a protected ETS table, so `count/1` and `snapshot/1` read without a round trip
  to the process. Only the anonymous visitor id and coarse attributes are held, and only for the
  window.
  """
  use GenServer

  alias Tally.Events.Event

  @table __MODULE__
  @feed_size 20

  @type visit :: %{
          path: String.t(),
          source: String.t(),
          country: String.t() | nil,
          name: String.t(),
          at: DateTime.t()
        }

  @doc false
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "The PubSub topic for a site."
  @spec topic(String.t()) :: String.t()
  def topic(site), do: "visitors:" <> site

  @doc "Subscribes the caller to a site's live updates."
  @spec subscribe(String.t()) :: :ok | {:error, term()}
  def subscribe(site), do: Phoenix.PubSub.subscribe(Tally.PubSub, topic(site))

  @doc """
  Records activity for the event's visitor.
  """
  @spec touch(Event.t()) :: :ok
  def touch(%Event{} = event), do: GenServer.cast(__MODULE__, {:touch, event})

  @doc """
  Number of live visitors on a site.
  """
  @spec count(String.t()) :: non_neg_integer()
  def count(site) do
    cutoff = cutoff_unix(now())
    :ets.select_count(@table, [{{{site, :_}, :"$1", :_}, [{:>=, :"$1", cutoff}], [true]}])
  end

  @doc """
  Live visitors on a site with their current pages, sources and countries, plus the most recent
  events.
  """
  @spec snapshot(String.t()) :: map()
  def snapshot(site) do
    cutoff = cutoff_unix(now())

    entries =
      :ets.select(@table, [{{{site, :_}, :"$1", :"$2"}, [{:>=, :"$1", cutoff}], [:"$2"]}])

    %{
      site: site,
      visitors: length(entries),
      pages: top(entries, :path),
      sources: top(entries, :source),
      countries: top(entries, :country),
      feed: GenServer.call(__MODULE__, {:feed, site})
    }
  end

  @doc """
  Drops expired visitors now and broadcasts count changes (also runs on a timer).
  """
  @spec sweep() :: :ok
  def sweep, do: GenServer.call(__MODULE__, :sweep)

  @doc "Removes all live state (tests)."
  @spec reset() :: :ok
  def reset, do: GenServer.call(__MODULE__, :reset)

  # -- server -------------------------------------------------------------------------------------

  @impl true
  def init(_opts) do
    :ets.new(@table, [:set, :protected, :named_table, read_concurrency: true])
    schedule_sweep()
    {:ok, %{feeds: %{}, counts: %{}}}
  end

  @impl true
  def handle_cast({:touch, event}, state) do
    seen = DateTime.to_unix(event.timestamp)

    visit = %{
      path: event.path,
      source: event.source,
      country: event.country,
      name: event.name,
      at: event.timestamp
    }

    :ets.insert(@table, {{event.site, event.visitor_id}, seen, visit})
    broadcast(event.site, {:live_visit, event.site, visit})

    feeds = Map.update(state.feeds, event.site, [visit], &Enum.take([visit | &1], @feed_size))
    {:noreply, publish_count(%{state | feeds: feeds}, event.site)}
  end

  @impl true
  def handle_call({:feed, site}, _from, state),
    do: {:reply, Map.get(state.feeds, site, []), state}

  def handle_call(:sweep, _from, state), do: {:reply, :ok, do_sweep(state)}

  def handle_call(:reset, _from, _state) do
    :ets.delete_all_objects(@table)
    {:reply, :ok, %{feeds: %{}, counts: %{}}}
  end

  @impl true
  def handle_info(:sweep, state) do
    schedule_sweep()
    {:noreply, do_sweep(state)}
  end

  defp do_sweep(state) do
    cutoff = cutoff_unix(now())
    :ets.select_delete(@table, [{{:_, :"$1", :_}, [{:<, :"$1", cutoff}], [true]}])

    state.counts
    |> Map.keys()
    |> Enum.reduce(state, &publish_count(&2, &1))
    |> trim_feeds(cutoff)
  end

  defp trim_feeds(state, cutoff) do
    feeds =
      state.feeds
      |> Map.new(fn {site, feed} ->
        {site, Enum.filter(feed, &(DateTime.to_unix(&1.at) >= cutoff))}
      end)
      |> Map.reject(fn {_site, feed} -> feed == [] end)

    %{state | feeds: feeds}
  end

  defp publish_count(state, site) do
    count = count(site)

    if Map.get(state.counts, site) == count do
      state
    else
      broadcast(site, {:live_count, site, count})

      counts =
        if count == 0,
          do: Map.delete(state.counts, site),
          else: Map.put(state.counts, site, count)

      %{state | counts: counts}
    end
  end

  defp top(entries, key) do
    entries
    |> Enum.frequencies_by(&Map.get(&1, key))
    |> Enum.map(fn {name, visitors} -> %{name: name || "Unknown", visitors: visitors} end)
    |> Enum.sort_by(&{-&1.visitors, &1.name})
    |> Enum.take(10)
  end

  defp broadcast(site, message), do: Phoenix.PubSub.broadcast(Tally.PubSub, topic(site), message)

  defp cutoff_unix(now), do: DateTime.to_unix(now) - Keyword.get(config(), :window_seconds, 300)

  defp now, do: DateTime.utc_now()

  defp schedule_sweep,
    do: Process.send_after(self(), :sweep, Keyword.get(config(), :sweep_interval_ms, 5_000))

  defp config, do: Application.get_env(:tally, __MODULE__, [])
end
