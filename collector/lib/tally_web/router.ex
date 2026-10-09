defmodule TallyWeb.Router do
  use TallyWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TallyWeb do
    pipe_through :api

    get "/health", HealthController, :show
  end
end
