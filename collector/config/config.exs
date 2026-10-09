# General application configuration, loaded before any dependency. Environment-specific overrides
# live in dev.exs / test.exs / prod.exs, and environment variables are read in runtime.exs.
import Config

config :tally, TallyWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [formats: [json: TallyWeb.ErrorJSON], layout: false],
  pubsub_server: Tally.PubSub

# Sites this deployment accepts events for, plus their goals and funnels. TALLY_SITES overrides the
# list of domains at runtime; goals and funnels below apply to every site unless a site entry
# overrides them.
config :tally, Tally.Sites,
  sites: ["harrowfield.co"],
  goals: [
    %{name: "Purchase", type: :event, match: "Purchase"},
    %{name: "Add to cart", type: :event, match: "Add to cart"},
    %{name: "Begin checkout", type: :event, match: "Begin checkout"},
    %{name: "Newsletter signup", type: :event, match: "Newsletter signup"},
    %{name: "Visit /checkout/thank-you", type: :page, match: "/checkout/thank-you"}
  ],
  funnels: [
    %{
      name: "Checkout",
      steps: [
        %{name: "Viewed a product", type: :page, match: "/products/*"},
        %{name: "Added to cart", type: :event, match: "Add to cart"},
        %{name: "Began checkout", type: :event, match: "Begin checkout"},
        %{name: "Purchased", type: :event, match: "Purchase"}
      ]
    }
  ]

# Event buffering: a batch is flushed when it reaches max_batch events or max_wait_ms after the first
# buffered event, whichever comes first.
config :tally, Tally.Events.Buffer,
  max_batch: 500,
  max_wait_ms: 2_000,
  sinks: [Tally.Events.Store, Tally.Events.LogSink]

config :tally, Tally.Events.Store,
  retention_days: 400,
  prune_interval_ms: :timer.hours(1)

# A visitor counts as "live" for this long after their last event.
config :tally, Tally.Live,
  window_seconds: 300,
  sweep_interval_ms: 5_000

# Stats API keys: %{"key" => plan}. Set from TALLY_API_KEYS in runtime.exs.
config :tally, :api_keys, %{}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
