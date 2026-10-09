defmodule Tally.Stats.FunnelReport do
  @moduledoc """
  Funnel conversion: how many unique visitors completed each step, in order, within one visit.

  Steps are matched greedily in event order: a visit reaches step N when it has an event matching
  step N after an event matching step N-1. A visitor reaches a step if any of their visits did.
  """

  alias Tally.Stats.Funnel
  alias Tally.Stats.Goal
  alias Tally.Stats.Metrics
  alias Tally.Stats.Visit

  @type step :: %{
          name: String.t(),
          visitors: non_neg_integer(),
          of_first: float(),
          drop_off: float() | nil
        }

  @doc """
  The funnel's steps with visitor counts, % of the first step and drop-off since the previous step.
  """
  @spec run([Visit.t()], Funnel.t()) :: %{
          name: String.t(),
          steps: [step()],
          conversion_rate: float()
        }
  def run(visits, %Funnel{name: name, steps: steps}) do
    reached =
      visits
      |> Enum.group_by(& &1.visitor_id)
      |> Enum.map(fn {_visitor, visitor_visits} ->
        visitor_visits |> Enum.map(&steps_reached(&1, steps)) |> Enum.max(fn -> 0 end)
      end)

    counts = for index <- 1..length(steps), do: Enum.count(reached, &(&1 >= index))
    first = hd(counts)

    rows =
      steps
      |> Enum.zip(counts)
      |> Enum.with_index()
      |> Enum.map(fn {{step, count}, index} ->
        previous = if index > 0, do: Enum.at(counts, index - 1)

        %{
          name: step.name,
          visitors: count,
          of_first: Metrics.percent(count, first),
          drop_off: if(previous, do: 100.0 - Metrics.percent(count, previous))
        }
      end)

    total_visitors = length(reached)

    %{
      name: name,
      steps: rows,
      conversion_rate: Metrics.percent(List.last(counts), total_visitors)
    }
  end

  @doc """
  How many steps of the funnel one visit completed, in order.
  """
  @spec steps_reached(Visit.t(), [Goal.t()]) :: non_neg_integer()
  def steps_reached(%Visit{events: events}, steps) do
    Enum.reduce_while(events, steps, fn
      _event, [] ->
        {:halt, []}

      event, [current | rest] = remaining ->
        if Goal.matches?(current, event), do: {:cont, rest}, else: {:cont, remaining}
    end)
    |> then(&(length(steps) - length(&1)))
  end
end
