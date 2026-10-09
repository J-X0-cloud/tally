defmodule TallyWeb.FallbackController do
  @moduledoc """
  Translates `{:error, reason}` tuples returned by controller actions into JSON error responses.
  """
  use Phoenix.Controller, formats: [:json]

  import Plug.Conn

  def call(conn, {:error, {:bad_request, message}}) do
    error(conn, 400, "bad_request", message)
  end

  def call(conn, {:error, {:invalid, field, message}}) do
    error(conn, 400, "invalid_parameter", "#{field}: #{message}")
  end

  def call(conn, {:error, :not_found}) do
    error(conn, 404, "not_found", "Not found")
  end

  def call(conn, {:error, {:not_found, what}}) do
    error(conn, 404, "not_found", "Unknown #{what}")
  end

  def call(conn, {:error, :forbidden}) do
    error(conn, 403, "forbidden", "This key cannot read that site")
  end

  def call(conn, {:error, {:plan_required, feature, plan}}) do
    error(conn, 402, "plan_required", "#{feature} needs the #{plan} plan or higher")
  end

  defp error(conn, status, code, message) do
    conn
    |> put_status(status)
    |> json(%{error: code, message: message})
  end
end
