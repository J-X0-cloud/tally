defmodule TallyWeb.Router do
  use TallyWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  # The tracking script posts text/plain from every tracked site; no content negotiation.
  pipeline :ingest do
    plug TallyWeb.Plugs.CORS
  end

  pipeline :stats_api do
    plug :accepts, ["json"]
    plug TallyWeb.Plugs.ApiAuth
    plug TallyWeb.Plugs.RateLimit
  end

  scope "/", TallyWeb do
    pipe_through :ingest

    # api.tallystats.com/event, first-party proxies (/stats/event) and the original route.
    for path <- ["/api/event", "/event", "/stats/event"] do
      post path, EventController, :create
      options path, EventController, :create
    end
  end

  scope "/api", TallyWeb do
    pipe_through :api

    get "/health", HealthController, :show

    get "/demo", DemoController, :show
    get "/demo/ranges/:range", DemoController, :range
    get "/demo/breakdown", DemoController, :breakdown
    get "/demo/realtime", DemoController, :realtime

    get "/plans", PlanController, :index
    get "/plans/quote", PlanController, :quote
  end

  scope "/api/v1/stats/:site", TallyWeb do
    pipe_through :stats_api

    get "/aggregate", StatsController, :aggregate
    get "/timeseries", StatsController, :timeseries
    get "/breakdown", StatsController, :breakdown
    get "/goals", StatsController, :goals
    get "/funnel", StatsController, :funnel
    get "/realtime", StatsController, :realtime
  end
end
