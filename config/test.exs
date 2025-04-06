import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :passwordless, Passwordless.Repo,
  username: "postgres",
  password: "postgres",
  database: "passwordless_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :passwordless, PasswordlessWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "cPNzM6yNbuYM9FcYYtqL/PPFpiGQD5Tdxe4pRe8KYGFJ8gwI3Zgl6VL80H6pFeOp",
  server: true

# In test we don't send emails.
config :passwordless, Passwordless.Mailer, adapter: Swoosh.Adapters.Test

# Configures the secret manager
config :passwordless, :secret_manager, adapter: SecretManager.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Only validate simple things
config :passwordless, :email_validators, [:format, :domain]

config :passwordless, :env, :test

# Wallaby related settings:
config :wallaby, otp_app: :passwordless, screenshot_on_failure: true, js_logger: nil
config :passwordless, :sandbox, Ecto.Adapters.SQL.Sandbox

# Oban - Disable plugins, enqueueing scheduled jobs and job dispatching altogether when testing
config :passwordless, Oban, testing: :inline

config :exvcr,
  global_mock: true,
  vcr_cassette_library_dir: "test/support/fixtures/vcr_cassettes",
  filter_request_headers: ["Authorization"]
