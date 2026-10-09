defmodule TallyWeb.JSON do
  @moduledoc """
  Shapes domain data for JSON responses: snake_case keys become camelCase (the frontend's
  convention), dates become ISO 8601 strings, and structs become plain maps.

      iex> TallyWeb.JSON.camelize(%{"of_first" => [%{drop_off: nil}], prior_totals: %{bounce_rate: 1}})
      %{"priorTotals" => %{"bounceRate" => 1}, "ofFirst" => [%{"dropOff" => nil}]}
  """

  @doc "Recursively camelizes keys and normalises values."
  @spec camelize(term()) :: term()
  def camelize(%DateTime{} = value), do: DateTime.to_iso8601(value)
  def camelize(%Date{} = value), do: Date.to_iso8601(value)
  def camelize(%_{} = struct), do: struct |> Map.from_struct() |> camelize()

  def camelize(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {camel_key(key), camelize(value)} end)
  end

  def camelize(list) when is_list(list), do: Enum.map(list, &camelize/1)
  def camelize(other), do: other

  @doc """
  Converts one key.

      iex> TallyWeb.JSON.camel_key(:stats_api_per_hour)
      "statsApiPerHour"
  """
  @spec camel_key(atom() | String.t()) :: String.t()
  def camel_key(key) when is_atom(key), do: key |> Atom.to_string() |> camel_key()

  def camel_key(key) when is_binary(key) do
    case String.split(key, "_") do
      [single] -> single
      [first | rest] -> first <> Enum.map_join(rest, &String.capitalize/1)
    end
  end
end
