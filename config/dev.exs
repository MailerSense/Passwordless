import Config

# Configure your database
config :passwordless, Passwordless.Repo,
  username: "postgres",
  password: "postgres",
  database: "passwordless_dev",
  hostname: "localhost",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :passwordless, PasswordlessWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT") || "4000")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "yfiG2t5XIqa/w1Yat4YSRkuDM/rhSEeLlJY5WoOarMlSil3s0j0BZKw7b7i5oTSS",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]},
    tailwind_backpex: {Tailwind, :install_and_run, [:backpex, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading.
config :passwordless, PasswordlessWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/passwordless_web/.*(ex|heex)$",
      ~r"lib/passwordless_web/(controllers|live|views|components|templates)/.*(ex|heex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Include HEEx debug annotations as HTML comments in rendered markup
config :phoenix_live_view, :debug_heex_annotations, true

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Only care for format validation in development
config :passwordless, :email_validators, [:format, :domain]

# Run browser in on demand mode
config :passwordless, :browser, on_demand: true

# Configure clustering
config :libcluster,
  topologies: [
    passwordless: [
      strategy: Passwordless.Cluster.PostgresStrategy,
      config: [
        hostname: "localhost",
        username: "postgres",
        password: "postgres",
        database: "passwordless_dev",
        port: 5432,
        parameters: [],
        channel_name: "elixir_cluster"
      ]
    ]
  ]

config :passwordless, :env, :dev
