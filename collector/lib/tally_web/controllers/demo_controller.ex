defmodule TallyWeb.DemoController do
  @moduledoc """
  The public demo dashboard's data. The numbers are fixed for the life of a node, so responses
  are cacheable.
  """
  use TallyWeb, :controller

  alias Tally.Demo
  alias TallyWeb.JSON

  plug :cacheable

  @doc "`GET /api/demo`: the whole dashboard in one response."
  def show(conn, _params), do: json(conn, JSON.camelize(Demo.dashboard()))

  @doc "`GET /api/demo/ranges/:range`"
  def range(conn, %{"range" => range}) do
    with {:ok, data} <- Demo.range(range) do
      json(conn, JSON.camelize(data))
    end
  end

  @doc "`GET /api/demo/breakdown?dimension=sources&tab=channels&range=30d`"
  def breakdown(conn, params) do
    with {:ok, dimension} <- required(params, "dimension"),
         {:ok, tab} <- required(params, "tab"),
         {:ok, range} <- optional(params, "range", "30d"),
         {:ok, rows} <- Demo.breakdown(dimension, tab, range) do
      json(conn, %{dimension: dimension, tab: tab, range: range, rows: JSON.camelize(rows)})
    end
  end

  @doc "`GET /api/demo/realtime`"
  def realtime(conn, _params), do: json(conn, JSON.camelize(Demo.realtime()))

  defp cacheable(conn, _opts) do
    put_resp_header(conn, "cache-control", "public, max-age=300, stale-while-revalidate=3600")
  end
end
