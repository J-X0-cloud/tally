defmodule Tally.Events.Event do
  @moduledoc """
  What is stored per event.

  Note what is absent: no IP address, no user agent, no full referrer URL, no viewport width. The
  visitor id is a daily salted hash that cannot be linked to anything once the day's salt is gone.
  """

  @enforce_keys [:site, :name, :timestamp, :visitor_id, :path]
  defstruct [
    :site,
    :name,
    :timestamp,
    :visitor_id,
    :path,
    source: "Direct / None",
    channel: "Direct",
    utm: %{},
    country: nil,
    screen: "Desktop",
    browser: "Other",
    os: "Other",
    props: %{},
    revenue: nil
  ]

  @type t :: %__MODULE__{
          site: String.t(),
          name: String.t(),
          timestamp: DateTime.t(),
          visitor_id: String.t(),
          path: String.t(),
          source: String.t(),
          channel: String.t(),
          utm: %{optional(String.t()) => String.t()},
          country: String.t() | nil,
          screen: String.t(),
          browser: String.t(),
          os: String.t(),
          props: map(),
          revenue: %{amount: number(), currency: String.t()} | nil
        }

  @pageview "pageview"

  @doc "The event name the tracking script uses for page views."
  def pageview_name, do: @pageview

  @doc "Whether the event is a page view (as opposed to a custom event)."
  @spec pageview?(t()) :: boolean()
  def pageview?(%__MODULE__{name: name}), do: name == @pageview

  @doc "Timestamp as microseconds since the Unix epoch, used as the store's sort key."
  @spec unix_us(t()) :: integer()
  def unix_us(%__MODULE__{timestamp: ts}), do: DateTime.to_unix(ts, :microsecond)

  @doc """
  The event as a plain map for NDJSON output and API responses.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = event) do
    %{
      site: event.site,
      name: event.name,
      timestamp: DateTime.to_iso8601(event.timestamp),
      visitor_id: event.visitor_id,
      path: event.path,
      source: event.source,
      channel: event.channel,
      utm: event.utm,
      country: event.country,
      screen: event.screen,
      browser: event.browser,
      os: event.os,
      props: event.props,
      revenue: event.revenue
    }
  end

  defimpl Jason.Encoder do
    def encode(event, opts), do: Jason.Encode.map(Tally.Events.Event.to_map(event), opts)
  end
end
