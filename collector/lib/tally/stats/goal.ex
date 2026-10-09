defmodule Tally.Stats.Goal do
  @moduledoc """
  A conversion goal: either a custom event name (`type: :event`) or a page path pattern
  (`type: :page`, see `Tally.Stats.PathPattern`).
  """

  alias Tally.Events.Event
  alias Tally.Stats.PathPattern

  @enforce_keys [:name, :type, :match]
  defstruct [:name, :type, :match, :pattern]

  @type type :: :event | :page
  @type t :: %__MODULE__{
          name: String.t(),
          type: type(),
          match: String.t(),
          pattern: PathPattern.t() | nil
        }

  @doc """
  Builds a goal from a map with `:type` and `:match`, plus an optional display `:name`.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(attrs) when is_map(attrs) do
    attrs = Map.new(attrs, fn {key, value} -> {to_string(key), value} end)

    with {:ok, type} <- type(Map.get(attrs, "type")),
         {:ok, match} <- match(type, Map.get(attrs, "match")) do
      name = Map.get(attrs, "name") || default_name(type, match)

      {:ok,
       %__MODULE__{
         name: name,
         type: type,
         match: match,
         pattern: if(type == :page, do: PathPattern.compile(match))
       }}
    end
  end

  @doc "Like `new/1` but raises on invalid input (for configuration)."
  @spec new!(map()) :: t()
  def new!(attrs) do
    case new(attrs) do
      {:ok, goal} -> goal
      {:error, message} -> raise ArgumentError, "invalid goal #{inspect(attrs)}: #{message}"
    end
  end

  @doc """
  Whether an event completes the goal. Page goals only count page views.
  """
  @spec matches?(t(), Event.t()) :: boolean()
  def matches?(%__MODULE__{type: :event, match: name}, %Event{name: event_name}),
    do: name == event_name

  def matches?(%__MODULE__{type: :page, pattern: pattern}, %Event{} = event),
    do: Event.pageview?(event) and PathPattern.match?(pattern, event.path)

  defp type(type) when type in [:event, :page], do: {:ok, type}
  defp type("event"), do: {:ok, :event}
  defp type("page"), do: {:ok, :page}
  defp type(_), do: {:error, "type must be event or page"}

  defp match(:page, "/" <> _ = path), do: {:ok, path}
  defp match(:page, _), do: {:error, "a page goal must match a path starting with /"}

  defp match(:event, name) when is_binary(name) do
    case String.trim(name) do
      "" -> {:error, "an event goal needs an event name"}
      "pageview" -> {:error, "use a page goal to count page views"}
      trimmed -> {:ok, trimmed}
    end
  end

  defp match(:event, _), do: {:error, "an event goal needs an event name"}

  defp default_name(:event, name), do: name
  defp default_name(:page, path), do: "Visit " <> path
end
