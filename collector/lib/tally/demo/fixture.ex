defmodule Tally.Demo.Fixture do
  @moduledoc """
  The demo site's seed data, read from `priv/demo/harrowfield.json` at compile time: the site,
  the snapshot moment, the traffic model's parameters, breakdown dimensions with typical shares,
  goals, the checkout funnel and the realtime card's feed.

  Harrowfield Supply is a fictional handmade ceramics store.
  """

  @path Path.join([__DIR__, "..", "..", "..", "priv", "demo", "harrowfield.json"])
  @external_resource @path
  @data @path |> File.read!() |> Jason.decode!()

  @doc "The whole fixture, with string keys as in the file."
  @spec data() :: map()
  def data, do: @data

  @doc "The demo site."
  @spec site() :: map()
  def site, do: @data["site"]

  @doc "The moment the demo dashboard is frozen at: a date plus local hour and minute."
  @spec snapshot() :: %{today: Date.t(), hour: 0..23, minute: 0..59}
  def snapshot do
    %{"today" => today, "hour" => hour, "minute" => minute} = @data["snapshot"]
    %{today: Date.from_iso8601!(today), hour: hour, minute: minute}
  end

  @doc "Traffic model parameters."
  @spec traffic() :: map()
  def traffic do
    traffic = @data["traffic"]

    %{
      day_count: traffic["dayCount"],
      seed: traffic["seed"],
      average_order: traffic["averageOrder"],
      weekday: List.to_tuple(traffic["weekday"]),
      spikes: Map.new(traffic["spikes"], fn {date, x} -> {Date.from_iso8601!(date), x} end),
      hour_shape: traffic["hourShape"]
    }
  end

  @doc "Breakdown dimensions, in panel order."
  @spec dimensions() :: [map()]
  def dimensions, do: @data["dimensions"]

  @doc "Looks up a dimension by key."
  @spec dimension(String.t()) :: {:ok, map()} | {:error, {:not_found, String.t()}}
  def dimension(key) do
    case Enum.find(dimensions(), &(&1["key"] == key)) do
      nil -> {:error, {:not_found, "dimension"}}
      dimension -> {:ok, dimension}
    end
  end

  @doc "Looks up a tab within a dimension."
  @spec tab(String.t(), String.t()) :: {:ok, map()} | {:error, {:not_found, String.t()}}
  def tab(dimension_key, tab_key) do
    with {:ok, dimension} <- dimension(dimension_key) do
      case Enum.find(dimension["tabs"], &(&1["key"] == tab_key)) do
        nil -> {:error, {:not_found, "tab"}}
        tab -> {:ok, tab}
      end
    end
  end

  @doc "Goal definitions: name, share of visitors converting, completions per visitor, revenue."
  @spec goals() :: [map()]
  def goals, do: @data["goals"]

  @doc "Checkout funnel steps as shares of unique visitors."
  @spec checkout_funnel() :: [map()]
  def checkout_funnel, do: @data["checkoutFunnel"]

  @doc "The realtime card: visitors-per-minute spark and the live feed."
  @spec realtime() :: map()
  def realtime, do: @data["realtime"]
end
