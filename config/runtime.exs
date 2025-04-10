import Config
import Util, only: [append_if: 3]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_OAUTH_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_OAUTH_SECRET")

config :stripity_stripe,
  api_key: System.get_env("STRIPE_SECRET"),
  signing_secret: System.get_env("STRIPE_WEBHOOK_SECRET")

config :passwordless, :stripe_production_mode, System.get_env("STRIPE_PRODUCTION_MODE") == "true"

if config_env() == :prod do
  postgres_user = System.get_env("POSTGRES_USER") || raise "env variable POSTGRES_USER is missing"

  postgres_password =
    System.get_env("POSTGRES_PASSWORD") || raise "env variable POSTGRES_PASSWORD is missing"

  postgres_host = System.get_env("POSTGRES_HOST") || raise "env variable POSTGRES_HOST is missing"
  postgres_port = System.get_env("POSTGRES_PORT") || raise "env variable POSTGRES_PORT is missing"

  postgres_db_name =
    System.get_env("POSTGRES_DB_NAME") || raise "env variable POSTGRES_DB_NAME is missing"

  database_url =
    "ecto://#{postgres_user}:#{postgres_password}@#{postgres_host}:#{postgres_port}/#{postgres_db_name}"

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :passwordless, Passwordless.Repo,
    url: database_url,
    ssl: AwsRdsCAStore.ssl_opts(database_url),
    timeout: if(System.get_env("DATABASE_MIGRATION"), do: :timer.seconds(60), else: :timer.seconds(15)),
    pool_size: String.to_integer(System.get_env("POOL_SIZE", "20")),
    socket_options: maybe_ipv6

  redis_host = System.get_env("REDIS_HOST")
  redis_port = System.get_env("REDIS_PORT", "6379")
  redis_auth_token = System.get_env("REDIS_AUTH_TOKEN")

  config :passwordless, :redis,
    host: redis_host,
    port: redis_port,
    auth_token: redis_auth_token

  if redis_host do
    config :hammer,
      backend:
        {Hammer.Backend.Redis,
         [
           delete_buckets_timeout: 100_000,
           key_prefix: "passwordless:rate_limiter",
           expiry_ms: 60_000 * 60 * 2,
           redix_config: [
             ssl: true,
             host: redis_host,
             port: String.to_integer(redis_port),
             password: redis_auth_token,
             socket_opts: [
               customize_hostname_check: [
                 match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
               ]
             ]
           ]
         ]}
  else
    config :hammer,
      backend: {
        Hammer.Backend.ETS,
        [
          expiry_ms: 60_000 * 60 * 4,
          cleanup_interval_ms: 60_000 * 10
        ]
      }
  end

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host =
    System.get_env("PHX_HOST") ||
      raise """
      Environment variable PHX_HOST is missing.
      This is needed for your URLs to be generated properly.
      Set it to your domain name. eg 'example.com' or 'subdomain.example.com'."
      """

  port = String.to_integer(System.get_env("PORT") || "8000")

  config :passwordless, PasswordlessWeb.Endpoint,
    server: is_nil(System.get_env("DATABASE_MIGRATION")),
    compress: true,
    url: [host: host, scheme: "https", port: 443],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  config :stripity_stripe,
    api_key: System.get_env("STRIPE_SECRET"),
    signing_secret: System.get_env("STRIPE_WEBHOOK_SECRET")

  # Configure clustering
  config :libcluster,
    topologies: [
      passwordless: [
        strategy: Util.PostgresStrategy,
        config: [
          hostname: postgres_host,
          username: postgres_user,
          password: postgres_password,
          database: postgres_db_name,
          port: String.to_integer(postgres_port),
          parameters: [],
          ssl: AwsRdsCAStore.ssl_opts(database_url),
          channel_name: "elixir_cluster"
        ]
      ]
    ]

  # Configures the media uploader to S3
  config :passwordless, :s3,
    customer_media: [
      bucket: System.get_env("CUSTOMER_MEDIA_BUCKET"),
      cdn_url: System.get_env("CUSTOMER_MEDIA_CDN_URL")
    ]

  config :passwordless, :aws_current,
    region: System.get_env("AWS_REGION"),
    account: System.get_env("AWS_ACCOUNT")
end

# Reduce XSS risks by declaring which dynamic resources are allowed to load
# If you use any CDNs, whitelist them here.

config :passwordless, :content_security_policy,
  default_src: append_if(["'self'"], "https://#{System.get_env("CDN_HOST")}", config_env() == :prod),
  connect_src:
    [
      "*.amazonaws.com"
    ]
    |> append_if(
      ["wss://#{System.get_env("PHX_HOST")}", "https://#{System.get_env("PHX_HOST")}"],
      config_env() == :prod
    )
    |> append_if(
      [
        "ws://localhost:#{String.to_integer(System.get_env("PORT", "4000"))}",
        "http://localhost:#{String.to_integer(System.get_env("PORT", "4000"))}"
      ],
      config_env() != :prod
    ),
  img_src: [
    "https:",
    "'self'",
    "data:"
  ],
  font_src: [
    "https://rsms.me",
    "https://*.googleapis.com",
    "https://*.gstatic.com"
  ],
  style_src:
    append_if(
      ["'self'", "'unsafe-inline'", "https://rsms.me", "https://*.googleapis.com", "https://*.gstatic.com"],
      "https://#{System.get_env("CDN_HOST")}",
      config_env() == :prod
    ),
  script_src: append_if(["'self'", "'nonce'"], "https://#{System.get_env("CDN_HOST")}", config_env() == :prod),
  frame_src:
    append_if(
      ["https://*.passwordless.tools"],
      "http://localhost:#{String.to_integer(System.get_env("PORT", "4000"))}",
      config_env() != :prod
    )
