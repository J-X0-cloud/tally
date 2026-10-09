import Config

config :tally, TallyWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "JKm3v5aQLa9f+k2JiWd2jWKZ2tJ2Yk1jq4VtSS7BQSvUFrqJiVZsP5fJIqUnUkM5",
  watchers: []

# A local key so the stats API can be tried with curl during development.
config :tally, :api_keys, %{"dev-key" => "business"}

config :logger, :default_formatter, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
