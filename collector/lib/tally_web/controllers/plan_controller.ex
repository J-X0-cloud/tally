defmodule TallyWeb.PlanController do
  @moduledoc """
  The plan catalog for the pricing page, and single price quotes.
  """
  use TallyWeb, :controller

  alias Tally.Billing.Plans
  alias TallyWeb.JSON

  @doc "`GET /api/plans`: volumes, every plan's prices for both billing periods, and the comparison."
  def index(conn, _params) do
    conn
    |> put_resp_header("cache-control", "public, max-age=300")
    |> json(
      JSON.camelize(%{
        volumes: Plans.volumes(),
        yearly_months_charged: Plans.yearly_months_charged(),
        plans: Plans.price_table(),
        comparison: Plans.comparison()
      })
    )
  end

  @doc "`GET /api/plans/quote?plan=growth&volume=100k&billing=yearly`"
  def quote(conn, params) do
    with {:ok, plan} <- required(params, "plan"),
         {:ok, volume} <- required(params, "volume"),
         {:ok, billing} <- one_of(params, "billing", ["monthly", "yearly"], "monthly"),
         {:ok, quote} <- Plans.quote(plan, volume, String.to_existing_atom(billing)) do
      json(conn, Map.merge(%{plan: plan, volume: volume, billing: billing}, quote))
    end
  end
end
