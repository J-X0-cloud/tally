defmodule Tally.Stats.Filter do
  @moduledoc """
  Segment filters for stats queries, in the compact form the API accepts:

      source==Instagram|Pinterest;page==/products/*;screen==Mobile;country!=US

  Clauses are separated by `;` and all must hold. Each clause is `dimension` `operator` `values`,
  with alternatives separated by `|`:

    * `==` the value is any of the alternatives;
    * `!=` the value is none of them;
    * `~=` the value contains any of them (case-insensitive).

  Visit dimensions (`source`, `channel`, `utm_*`, `country`, `screen`, `browser`, `os`,
  `entry_page`, `exit_page`) test the visit's own attribute. `page` keeps visits that viewed a
  matching page (path wildcards allowed), and `event` keeps visits with a matching custom event.
  """

  alias Tally.Events.Event
  alias Tally.Stats.PathPattern
  alias Tally.Stats.Visit

  @enforce_keys [:dimension, :operator, :values]
  defstruct [:dimension, :operator, :values]

  @type operator :: :is | :is_not | :contains
  @type t :: %__MODULE__{dimension: String.t(), operator: operator(), values: [String.t()]}

  @visit_dimensions ~w(source channel utm_source utm_medium utm_campaign utm_term utm_content
                       country screen browser os entry_page exit_page)
  @dimensions @visit_dimensions ++ ~w(page event)
  @max_clauses 10

  @doc "Every filterable dimension."
  def dimensions, do: @dimensions

  @doc """
  Parses a filter string. An empty or nil string means no filters.

      iex> {:ok, [filter]} = Tally.Stats.Filter.parse("source==Instagram|Pinterest")
      iex> {filter.dimension, filter.operator, filter.values}
      {"source", :is, ["Instagram", "Pinterest"]}
  """
  @spec parse(String.t() | nil) :: {:ok, [t()]} | {:error, {:invalid, String.t(), String.t()}}
  def parse(nil), do: {:ok, []}

  def parse(string) when is_binary(string) do
    clauses = string |> String.split(";") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

    if length(clauses) > @max_clauses do
      {:error, {:invalid, "filters", "at most #{@max_clauses} clauses are allowed"}}
    else
      clauses
      |> Enum.reduce_while({:ok, []}, fn clause, {:ok, acc} ->
        case parse_clause(clause) do
          {:ok, filter} -> {:cont, {:ok, [filter | acc]}}
          {:error, message} -> {:halt, {:error, {:invalid, "filters", message}}}
        end
      end)
      |> case do
        {:ok, filters} -> {:ok, Enum.reverse(filters)}
        error -> error
      end
    end
  end

  @doc """
  Keeps the visits that satisfy every filter.
  """
  @spec apply([Visit.t()], [t()]) :: [Visit.t()]
  def apply(visits, []), do: visits
  def apply(visits, filters), do: Enum.filter(visits, &matches_all?(&1, filters))

  @doc """
  Whether one visit satisfies every filter.
  """
  @spec matches_all?(Visit.t(), [t()]) :: boolean()
  def matches_all?(visit, filters), do: Enum.all?(filters, &matches?(visit, &1))

  defp matches?(visit, %__MODULE__{dimension: "page"} = filter) do
    test(filter, Visit.pages(visit), &path_match?/2)
  end

  defp matches?(visit, %__MODULE__{dimension: "event"} = filter) do
    names = for event <- visit.events, not Event.pageview?(event), do: event.name
    test(filter, names, &(&1 == &2))
  end

  defp matches?(visit, %__MODULE__{dimension: dimension} = filter) do
    value = visit_value(visit, dimension)
    pattern? = dimension in ["entry_page", "exit_page"]
    test(filter, List.wrap(value), if(pattern?, do: &path_match?/2, else: &(&1 == &2)))
  end

  # For multi-valued dimensions (pages, events) `is` means "any viewed page matches" and `is_not`
  # means "no viewed page matches".
  defp test(%__MODULE__{operator: :is, values: values}, actual, eq),
    do: Enum.any?(actual, fn a -> Enum.any?(values, &eq.(&1, a)) end)

  defp test(%__MODULE__{operator: :is_not, values: values}, actual, eq),
    do: not Enum.any?(actual, fn a -> Enum.any?(values, &eq.(&1, a)) end)

  defp test(%__MODULE__{operator: :contains, values: values}, actual, _eq) do
    needles = Enum.map(values, &String.downcase/1)
    Enum.any?(actual, fn a -> Enum.any?(needles, &String.contains?(String.downcase(a), &1)) end)
  end

  defp path_match?(pattern, path), do: PathPattern.match?(pattern, path)

  @doc """
  The value of a visit dimension (`nil` when absent).
  """
  @spec visit_value(Visit.t(), String.t()) :: String.t() | nil
  def visit_value(visit, "source"), do: visit.source
  def visit_value(visit, "channel"), do: visit.channel
  def visit_value(visit, "country"), do: visit.country
  def visit_value(visit, "screen"), do: visit.screen
  def visit_value(visit, "browser"), do: visit.browser
  def visit_value(visit, "os"), do: visit.os
  def visit_value(visit, "entry_page"), do: visit.entry_page
  def visit_value(visit, "exit_page"), do: visit.exit_page
  def visit_value(visit, "utm_" <> key), do: Map.get(visit.utm, key)

  defp parse_clause(clause) do
    case Regex.run(~r/^([a-z_]+)\s*(==|!=|~=)\s*(.+)$/s, clause) do
      [_, dimension, operator, raw] when dimension in @dimensions ->
        values = raw |> String.split("|") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

        if values == [] do
          {:error, "#{dimension} needs at least one value"}
        else
          {:ok, %__MODULE__{dimension: dimension, operator: operator(operator), values: values}}
        end

      [_, dimension, _, _] ->
        {:error, "unknown dimension #{inspect(dimension)}"}

      nil ->
        {:error, "clauses look like dimension==value, got #{inspect(clause)}"}
    end
  end

  defp operator("=="), do: :is
  defp operator("!="), do: :is_not
  defp operator("~="), do: :contains
end
