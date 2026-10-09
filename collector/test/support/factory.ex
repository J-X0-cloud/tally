defmodule Tally.Factory do
  @moduledoc """
  Builders for events and visits in tests.
  """

  alias Tally.Events.Event

  @doc """
  An event with sensible defaults; any field can be overridden. `:at` accepts a `DateTime` or
  seconds after `~U[2026-09-25 10:00:00Z]`.
  """
  def event(attrs \\ []) do
    attrs = Map.new(attrs)
    {at, attrs} = Map.pop(attrs, :at, 0)

    struct!(
      Event,
      Map.merge(
        %{
          site: "harrowfield.co",
          name: "pageview",
          timestamp: timestamp(at),
          visitor_id: "v1",
          path: "/",
          source: "Google",
          channel: "Organic Search",
          utm: %{},
          country: "US",
          screen: "Mobile",
          browser: "Safari",
          os: "iOS",
          props: %{},
          revenue: nil
        },
        attrs
      )
    )
  end

  @doc "A page view."
  def pageview(path, attrs \\ []), do: event([path: path] ++ attrs)

  @doc "A custom event."
  def custom(name, attrs \\ []), do: event([name: name] ++ attrs)

  @doc "The base timestamp plus `seconds`."
  def timestamp(%DateTime{} = at), do: at

  def timestamp(seconds) when is_integer(seconds),
    do: DateTime.add(~U[2026-09-25 10:00:00Z], seconds)
end
