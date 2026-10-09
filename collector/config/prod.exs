import Config

# TLS is terminated by the platform's edge (Railway, Fly, a load balancer). The collector also has to
# answer plain HTTP on the private network, where the Next.js frontend calls it, so there is no
# force_ssl redirect here.

config :logger, level: :info

# Runtime production configuration, including reading of environment variables, is done in
# config/runtime.exs.
