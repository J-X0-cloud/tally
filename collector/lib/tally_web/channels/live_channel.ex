defmodule TallyWeb.LiveChannel do
  @moduledoc """
  Channel `"live:<site>"`.

  On join the client receives a `"snapshot"` (live visitors, top pages, sources, countries and the
  recent feed). After that it receives `"visit"` for every event and `"count"` whenever the number
  of live visitors changes, plus Phoenix Presence `"presence_state"` / `"presence_diff"` messages
  for the people watching.
  """
  use TallyWeb, :channel

  alias Tally.Live
  alias Tally.Sites
  alias TallyWeb.Presence

  @impl true
  def join("live:" <> site, _payload, socket) do
    case Sites.fetch(site) do
      {:ok, site} ->
        :ok = Live.subscribe(site)
        send(self(), :after_join)
        {:ok, assign(socket, :site, site)}

      {:error, _} ->
        {:error, %{reason: "unknown site"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.viewer, %{
        online_at: System.system_time(:second),
        plan: socket.assigns.plan
      })

    push(socket, "presence_state", Presence.list(socket))
    push(socket, "snapshot", Live.snapshot(socket.assigns.site))
    {:noreply, socket}
  end

  def handle_info({:live_visit, _site, visit}, socket) do
    push(socket, "visit", %{visit | at: DateTime.to_iso8601(visit.at)})
    {:noreply, socket}
  end

  def handle_info({:live_count, _site, count}, socket) do
    push(socket, "count", %{visitors: count})
    {:noreply, socket}
  end

  @impl true
  def handle_in("snapshot", _payload, socket) do
    {:reply, {:ok, Live.snapshot(socket.assigns.site)}, socket}
  end
end
