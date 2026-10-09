defmodule TallyWeb.LiveSocket do
  @moduledoc """
  WebSocket for live visitor updates, at `/live/websocket`. Connect with a Stats API key:

      new Socket("/live", { params: { token: "..." } })
  """
  use Phoenix.Socket

  alias Tally.Billing.ApiKeys

  channel "live:*", TallyWeb.LiveChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) when is_binary(token) do
    case ApiKeys.lookup(token) do
      {:ok, plan} ->
        viewer = Base.url_encode64(:crypto.strong_rand_bytes(9), padding: false)
        {:ok, assign(socket, plan: plan, viewer: viewer)}

      :error ->
        {:error, :unauthorized}
    end
  end

  def connect(_params, _socket, _connect_info), do: {:error, :unauthorized}

  @impl true
  def id(socket), do: "viewer:" <> socket.assigns.viewer
end
