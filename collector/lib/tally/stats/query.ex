defmodule Tally.Stats.Query do
  @moduledoc """
  A validated stats query: site, period and segment filters, built from API parameters.

      Tally.Stats.Query.from_params("harrowfield.co", %{"period" => "30d", "filters" => "screen==Mobile"})
  """

  alias Tally.Stats.Filter
  alias Tally.Stats.Period

  @enforce_keys [:site, :period]
  defstruct [:site, :period, filters: []]

  @type t :: %__MODULE__{site: String.t(), period: Period.t(), filters: [Filter.t()]}

  @doc """
  Builds a query. Recognised parameters: `period` (default `30d`), `date` (anchor day, default
  today in UTC), `from` / `to` (for `custom`), and `filters`.
  """
  @spec from_params(String.t(), map()) ::
          {:ok, t()} | {:error, {:invalid, String.t(), String.t()}}
  def from_params(site, params) when is_map(params) do
    with {:ok, today} <- anchor(Map.get(params, "date")),
         {:ok, period} <-
           Period.new(Map.get(params, "period", "30d"),
             today: today,
             from: Map.get(params, "from"),
             to: Map.get(params, "to")
           ),
         {:ok, filters} <- Filter.parse(Map.get(params, "filters")) do
      {:ok, %__MODULE__{site: site, period: period, filters: filters}}
    end
  end

  @doc "The same query over the previous period."
  @spec previous(t()) :: t()
  def previous(%__MODULE__{period: period} = query),
    do: %{query | period: Period.previous(period)}

  defp anchor(nil), do: {:ok, Date.utc_today()}
  defp anchor(""), do: {:ok, Date.utc_today()}

  defp anchor(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> {:ok, date}
      {:error, _} -> {:error, {:invalid, "date", "must be a date like 2026-09-25"}}
    end
  end

  defp anchor(_), do: {:error, {:invalid, "date", "must be a date like 2026-09-25"}}
end
