defmodule Tally.Stats.Delta do
  @moduledoc """
  Period-over-period change for a KPI tile: the absolute % change as display text, its direction,
  and whether the change is good for this metric.
  """

  @enforce_keys [:text, :direction, :good, :change]
  defstruct [:text, :direction, :good, :change]

  @type t :: %__MODULE__{
          text: String.t(),
          direction: :up | :down,
          good: boolean(),
          change: float()
        }

  @doc """
  The change from `prior` to `current`. Changes under 10% keep one decimal.

      iex> Tally.Stats.Delta.new(110, 100)
      %Tally.Stats.Delta{text: "10%", direction: :up, good: true, change: 10.0}
      iex> Tally.Stats.Delta.new(38, 40, true)
      %Tally.Stats.Delta{text: "5.0%", direction: :down, good: true, change: -5.0}
  """
  @spec new(number(), number(), boolean()) :: t()
  def new(current, prior, lower_is_better \\ false) do
    change = if prior == 0, do: 0.0, else: (current - prior) / prior * 100
    magnitude = abs(change)

    %__MODULE__{
      text: format(magnitude) <> "%",
      direction: if(change > 0, do: :up, else: :down),
      good: if(lower_is_better, do: change < 0, else: change > 0),
      change: change
    }
  end

  # Mirrors JavaScript's toFixed(1) / Math.round so the dashboard text is unchanged.
  defp format(magnitude) when magnitude < 10,
    do: :erlang.float_to_binary(magnitude / 1, decimals: 1)

  defp format(magnitude), do: magnitude |> round_half_up() |> Integer.to_string()

  defp round_half_up(value), do: trunc(Float.floor(value + 0.5))

  defimpl Jason.Encoder do
    def encode(delta, opts) do
      Jason.Encode.map(
        %{text: delta.text, direction: delta.direction, good: delta.good, change: delta.change},
        opts
      )
    end
  end
end
