defmodule Tally.Stats.GoalReport do
  @moduledoc """
  Goal conversions: for each goal, how many unique visitors completed it, how many times, the
  conversion rate against all visitors, and attached revenue.
  """

  alias Tally.Stats.Goal
  alias Tally.Stats.Metrics
  alias Tally.Stats.Visit

  @type row :: %{
          name: String.t(),
          type: Goal.type(),
          uniques: non_neg_integer(),
          total: non_neg_integer(),
          conversion_rate: float(),
          revenue: %{amount: float(), currency: String.t()} | nil
        }

  @doc """
  One row per goal, in the goals' configured order.
  """
  @spec run([Visit.t()], [Goal.t()]) :: [row()]
  def run(visits, goals) do
    total_visitors = visits |> Enum.uniq_by(& &1.visitor_id) |> length()

    Enum.map(goals, fn goal ->
      matches =
        for visit <- visits, event <- visit.events, Goal.matches?(goal, event), do: {visit, event}

      uniques =
        matches |> Enum.map(fn {visit, _} -> visit.visitor_id end) |> Enum.uniq() |> length()

      %{
        name: goal.name,
        type: goal.type,
        uniques: uniques,
        total: length(matches),
        conversion_rate: Metrics.percent(uniques, total_visitors),
        revenue: revenue(Enum.map(matches, &elem(&1, 1)))
      }
    end)
  end

  # Revenue in the goal's main currency (the one with the largest total). Mixed-currency goals are
  # rare; converting would need exchange rates the collector doesn't have.
  defp revenue(events) do
    events
    |> Enum.filter(& &1.revenue)
    |> Enum.group_by(& &1.revenue.currency, & &1.revenue.amount)
    |> Enum.map(fn {currency, amounts} ->
      %{currency: currency, amount: Enum.sum(amounts) / 1}
    end)
    |> Enum.max_by(& &1.amount, fn -> nil end)
  end
end
