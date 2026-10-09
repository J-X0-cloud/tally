defmodule Tally.Stats.Funnel do
  @moduledoc """
  A funnel definition: two to eight ordered steps, each a page pattern or a custom event, that a
  visitor has to complete in order within one visit.

  Steps can also be parsed from the compact form the stats API accepts:

      "page:/products/*|event:Add to cart|event:Purchase"
  """

  alias Tally.Stats.Goal

  @enforce_keys [:name, :steps]
  defstruct [:name, :steps]

  @type t :: %__MODULE__{name: String.t(), steps: [Goal.t()]}

  @min_steps 2
  @max_steps 8

  @doc """
  Builds a funnel from a map with `:name` and `:steps` (maps accepted by `Tally.Stats.Goal.new/1`).
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(attrs) when is_map(attrs) do
    attrs = Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
    name = Map.get(attrs, "name") || "Funnel"

    with {:ok, steps} <- steps(Map.get(attrs, "steps")) do
      {:ok, %__MODULE__{name: name, steps: steps}}
    end
  end

  @doc "Like `new/1` but raises on invalid input (for configuration)."
  @spec new!(map()) :: t()
  def new!(attrs) do
    case new(attrs) do
      {:ok, funnel} -> funnel
      {:error, message} -> raise ArgumentError, "invalid funnel #{inspect(attrs)}: #{message}"
    end
  end

  @doc """
  Parses the compact `type:match|type:match` form.

      iex> {:ok, funnel} = Tally.Stats.Funnel.parse("page:/products/*|event:Purchase")
      iex> Enum.map(funnel.steps, & &1.name)
      ["Visit /products/*", "Purchase"]
  """
  @spec parse(String.t(), String.t()) :: {:ok, t()} | {:error, String.t()}
  def parse(spec, name \\ "Custom funnel") when is_binary(spec) do
    spec
    |> String.split("|", trim: true)
    |> Enum.reduce_while({:ok, []}, fn part, {:ok, acc} ->
      case String.split(part, ":", parts: 2) do
        [type, match] when type in ["page", "event"] ->
          {:cont, {:ok, [%{type: type, match: String.trim(match)} | acc]}}

        _ ->
          {:halt, {:error, "steps must look like page:/path or event:Name, got #{inspect(part)}"}}
      end
    end)
    |> case do
      {:ok, steps} -> new(%{name: name, steps: Enum.reverse(steps)})
      error -> error
    end
  end

  defp steps(steps) when is_list(steps) and length(steps) < @min_steps,
    do: {:error, "a funnel needs at least #{@min_steps} steps"}

  defp steps(steps) when is_list(steps) and length(steps) > @max_steps,
    do: {:error, "a funnel can have at most #{@max_steps} steps"}

  defp steps(steps) when is_list(steps) do
    steps
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, []}, fn {step, index}, {:ok, acc} ->
      case Goal.new(step) do
        {:ok, goal} -> {:cont, {:ok, [goal | acc]}}
        {:error, message} -> {:halt, {:error, "step #{index}: #{message}"}}
      end
    end)
    |> case do
      {:ok, goals} -> {:ok, Enum.reverse(goals)}
      error -> error
    end
  end

  defp steps(_), do: {:error, "steps must be a list"}
end
