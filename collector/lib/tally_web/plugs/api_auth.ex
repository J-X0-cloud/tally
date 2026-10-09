defmodule TallyWeb.Plugs.ApiAuth do
  @moduledoc """
  Authenticates Stats API requests with `Authorization: Bearer <key>` and assigns the key's plan
  (`:plan`) and a non-reversible fingerprint (`:api_key_id`) for rate limiting.
  """
  @behaviour Plug

  import Plug.Conn

  alias Tally.Billing.ApiKeys

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    with ["Bearer " <> key] <- get_req_header(conn, "authorization"),
         key = String.trim(key),
         {:ok, plan} <- ApiKeys.lookup(key) do
      conn
      |> assign(:plan, plan)
      |> assign(:api_key_id, ApiKeys.fingerprint(key))
    else
      _ ->
        conn
        |> put_resp_header("www-authenticate", ~s(Bearer realm="tally"))
        |> put_status(401)
        |> Phoenix.Controller.json(%{
          error: "unauthorized",
          message: "Send a Stats API key as a Bearer token"
        })
        |> halt()
    end
  end
end
