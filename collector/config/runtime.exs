import Config

# Runtime configuration for every environment, including releases. Everything a deployment needs is
# read from environment variables here.

if System.get_env("PHX_SERVER") do
  config :tally, TallyWeb.Endpoint, server: true
end

config :tally, TallyWeb.Endpoint, http: [port: String.to_integer(System.get_env("PORT", "4000"))]

split_list = fn value ->
  value
  |> String.split(",")
  |> Enum.map(&(&1 |> String.trim() |> String.downcase()))
  |> Enum.reject(&(&1 == ""))
end

# Comma-separated domains, e.g. "harrowfield.co,shop.example.com".
if sites = System.get_env("TALLY_SITES") do
  config :tally, Tally.Sites, sites: split_list.(sites)
end

# Comma-separated "key:plan" pairs, e.g. "k_9f2c...:growth,k_71ab...:business".
if keys = System.get_env("TALLY_API_KEYS") do
  api_keys =
    keys
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Map.new(fn pair ->
      case String.split(pair, ":", parts: 2) do
        [key, plan] -> {String.trim(key), plan |> String.trim() |> String.downcase()}
        [key] -> {String.trim(key), "starter"}
      end
    end)

  config :tally, :api_keys, api_keys
end

if retention = System.get_env("TALLY_RETENTION_DAYS") do
  config :tally, Tally.Events.Store, retention_days: String.to_integer(retention)
end

if config_env() == :prod do
  # Nothing the collector signs outlives the process (there are no sessions or cookies), so a random
  # key is acceptable when SECRET_KEY_BASE is not set.
  secret_key_base =
    case System.get_env("SECRET_KEY_BASE") do
      blank when blank in [nil, ""] -> Base.encode64(:crypto.strong_rand_bytes(48))
      value -> value
    end

  host = System.get_env("PHX_HOST") || "localhost"

  config :tally, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :tally, TallyWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}],
    check_origin: false,
    secret_key_base: secret_key_base
end
