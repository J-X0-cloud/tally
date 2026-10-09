import Config

config :tally, TallyWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "rU+p3f3givbAjUCr+m/FLlR27YPD2LwCYKfwXHqWXezWs6BOOrhuQ7ea2aTv4ahj",
  server: false

config :tally, Tally.Sites, sites: ["harrowfield.co", "example.org"]

# Tests flush explicitly; the NDJSON log sink stays quiet.
config :tally, Tally.Events.Buffer,
  max_batch: 500,
  max_wait_ms: 60_000,
  sinks: [Tally.Events.Store]

config :tally, :api_keys, %{"test-growth" => "growth", "test-business" => "business"}

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime
