defmodule TallyWeb do
  @moduledoc """
  The web interface of the collector: the ingest endpoint, the stats and demo APIs, and the live
  visitor socket.
  """

  def static_paths, do: ~w(robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:json]

      import Plug.Conn
      import TallyWeb.Params

      action_fallback TallyWeb.FallbackController
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/channel/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
