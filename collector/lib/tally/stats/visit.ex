defmodule Tally.Stats.Visit do
  @moduledoc """
  A visit (session): consecutive events from one visitor with no gap longer than 30 minutes.

  Source, campaign, location and device are those of the visit's first event; the entry page is the
  first page viewed and the exit page the last. A visit bounces when it has at most one page view and
  no custom events.
  """

  alias Tally.Events.Event

  @enforce_keys [:visitor_id, :events]
  defstruct [
    :visitor_id,
    :start,
    :finish,
    :entry_page,
    :exit_page,
    :source,
    :channel,
    :country,
    :screen,
    :browser,
    :os,
    utm: %{},
    pageviews: 0,
    custom_events: 0,
    events: []
  ]

  @type t :: %__MODULE__{
          visitor_id: String.t(),
          start: DateTime.t(),
          finish: DateTime.t(),
          entry_page: String.t(),
          exit_page: String.t(),
          source: String.t(),
          channel: String.t(),
          country: String.t() | nil,
          screen: String.t(),
          browser: String.t(),
          os: String.t(),
          utm: map(),
          pageviews: non_neg_integer(),
          custom_events: non_neg_integer(),
          events: [Event.t()]
        }

  @timeout_seconds 30 * 60

  @doc "Inactivity after which the next event starts a new visit, in seconds."
  def timeout_seconds, do: @timeout_seconds

  @doc """
  Groups events (in any order) into visits, ordered by start time.
  """
  @spec build([Event.t()]) :: [t()]
  def build(events) when is_list(events) do
    events
    |> Enum.group_by(& &1.visitor_id)
    |> Enum.flat_map(fn {_visitor, visitor_events} ->
      visitor_events
      |> Enum.sort_by(&Event.unix_us/1)
      |> split_sessions()
      |> Enum.map(&from_events/1)
    end)
    |> Enum.sort_by(&DateTime.to_unix(&1.start, :microsecond))
  end

  @doc "Visit length in seconds, from the first to the last event."
  @spec duration(t()) :: non_neg_integer()
  def duration(%__MODULE__{start: start, finish: finish}),
    do: DateTime.diff(finish, start, :second)

  @doc "Whether the visit bounced."
  @spec bounce?(t()) :: boolean()
  def bounce?(%__MODULE__{pageviews: pageviews, custom_events: custom}),
    do: pageviews <= 1 and custom == 0

  @doc "Page paths viewed in this visit, in order."
  @spec pages(t()) :: [String.t()]
  def pages(%__MODULE__{events: events}) do
    for event <- events, Event.pageview?(event), do: event.path
  end

  defp split_sessions([first | rest]) do
    {sessions, current, _last} =
      Enum.reduce(rest, {[], [first], first}, fn event, {sessions, current, last} ->
        if DateTime.diff(event.timestamp, last.timestamp, :second) > @timeout_seconds do
          {[Enum.reverse(current) | sessions], [event], event}
        else
          {sessions, [event | current], event}
        end
      end)

    Enum.reverse([Enum.reverse(current) | sessions])
  end

  defp from_events([first | _] = events) do
    last = List.last(events)
    pageviews = Enum.filter(events, &Event.pageview?/1)
    entry = List.first(pageviews) || first
    exit = List.last(pageviews) || last

    %__MODULE__{
      visitor_id: first.visitor_id,
      start: first.timestamp,
      finish: last.timestamp,
      entry_page: entry.path,
      exit_page: exit.path,
      source: first.source,
      channel: first.channel,
      utm: first.utm,
      country: first.country,
      screen: first.screen,
      browser: first.browser,
      os: first.os,
      pageviews: length(pageviews),
      custom_events: length(events) - length(pageviews),
      events: events
    }
  end
end
