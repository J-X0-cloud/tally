defmodule TallyWeb.Plugs.RateLimit do
  @moduledoc """
  Applies the plan's Stats API allowance (requests per hour) to the authenticated key and reports
  it in `x-ratelimit-*` headers. Plans without API access get 402.
  """
  @behaviour Plug

  import Plug.Conn

  alias Tally.Billing.Plans
  alias Tally.Billing.RateLimiter

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%{assigns: %{plan: plan, api_key_id: key_id}} = conn, _opts) do
    case Plans.limits(plan).stats_api_per_hour do
      nil ->
        cheapest = Plans.cheapest_with(:stats_api_per_hour)

        conn
        |> put_status(402)
        |> Phoenix.Controller.json(%{
          error: "plan_required",
          message: "The Stats API needs the #{cheapest["name"]} plan or higher"
        })
        |> halt()

      limit ->
        case RateLimiter.hit(key_id, limit) do
          {:allow, info} ->
            put_rate_headers(conn, info)

          {:deny, info} ->
            conn
            |> put_rate_headers(info)
            |> put_resp_header("retry-after", Integer.to_string(max(info.reset - now(), 1)))
            |> put_status(429)
            |> Phoenix.Controller.json(%{
              error: "rate_limited",
              message: "This key has used its #{limit} requests for this hour"
            })
            |> halt()
        end
    end
  end

  defp put_rate_headers(conn, %{limit: limit, remaining: remaining, reset: reset}) do
    conn
    |> put_resp_header("x-ratelimit-limit", Integer.to_string(limit))
    |> put_resp_header("x-ratelimit-remaining", Integer.to_string(remaining))
    |> put_resp_header("x-ratelimit-reset", Integer.to_string(reset))
  end

  defp now, do: System.system_time(:second)
end
