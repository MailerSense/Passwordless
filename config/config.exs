# General application configuration
import Config

config :passwordless,
  app_name: "Passwordless",
  business_name: "Passwordless",
  support_email: "hello@passwordless.tools",
  sales_email: "sales@passwordless.tools",
  logo_url_for_emails: "https://cdn.passwordlesstools.com/logos/passwordless.png",
  description:
    "Passwordless introduces code-first synthetic monitoring to secure the uptime and performance of your apps and websites",
  seo_description:
    "More than uptime checks - catch website bugs with Playwright and never miss regressions in production again. No complex setup required. Flexible pricing.",
  twitter_url: "https://x.com/Passwordless",
  facebook_url: "https://www.facebook.com/profile.php?id=61570653856696",
  linkedin_url: "https://www.linkedin.com/company/livecheckio",
  github_url: "https://github.com/Passwordless",
  keywords: [
    "monitoring as code",
    "synthetic monitoring"
  ]

# Configures the repo
config :passwordless,
  ecto_repos: [Passwordless.Repo],
  generators: [timestamp_type: :utc_datetime_usec],
  migration_primary_key: [type: :uuid]

config :passwordless, :multitenant,
  repo: Passwordless.Repo,
  tenant_field: :id,
  tenant_prefix: "app_",
  tenant_migrations: "tenant_migrations"

# Configures the session
config :passwordless, :session,
  key: "_session_key",
  store: :cookie,
  max_age: div(:timer.hours(24 * 30), 1000),
  http_only: true,
  signing_salt: "dp9YDk0w",
  encryption_salt: "9saWZiuk"

# Configures the endpoint
config :passwordless, PasswordlessWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: PasswordlessWeb.ErrorHTML, json: PasswordlessWeb.ErrorJSON],
    layout: {PasswordlessWeb.Layouts, :error},
    root_layout: {PasswordlessWeb.Layouts, :root}
  ],
  pubsub_server: Passwordless.PubSub,
  live_view: [signing_salt: "Fd8SWPu3"]

# Configures AWS
config :ex_aws,
  region: "eu-west-1",
  http_client: Passwordless.ExAwsClient

# Configures Oban
config :passwordless, Oban,
  repo: Passwordless.Repo,
  prefix: "oban",
  queues: [
    default: 100,
    mailer: [local_limit: 10, global_limit: 20],
    executor: [local_limit: 10, global_limit: 20],
    scheduler: [local_limit: 10, global_limit: 10],
    statistics: [local_limit: 10, global_limit: 10]
  ],
  engine: Oban.Pro.Engines.Smart,
  notifier: Oban.Notifiers.PG,
  plugins: [
    Oban.Pro.Plugins.DynamicLifeline,
    Oban.Pro.Plugins.DynamicPrioritizer,
    Oban.Pro.Plugins.DynamicPartitioner,
    {Oban.Pro.Plugins.DynamicCron, crontab: []}
  ]

config :money,
  default_currency: :USD,
  symbol: true,
  symbol_on_right: false,
  symbol_space: false

config :passwordless, :cors,
  allow_credentials: true,
  allow_headers: :all,
  allow_methods: :all,
  max_age: 600

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
config :passwordless, Passwordless.Mailer, adapter: Swoosh.Adapters.Local

# Configures the cache
config :passwordless, :cache, adapter: Passwordless.Cache.InMemory

# Configures the object storage
config :passwordless, :storage, adapter: Passwordless.Storage.Local

# Configures the rate limit
config :passwordless, :rate_limit, adapter: Passwordless.RateLimit.ETS

# Configures the billing provider
config :passwordless, :billing_provider, Passwordless.Billing.Providers.Stripe

config :passwordless, :hammer,
  ets: [
    clean_period: :timer.minutes(1)
  ]

# Configures the secret manager
config :passwordless, :secret_manager,
  adapter: Passwordless.SecretManager.Local,
  secret_name: "SM_LOCAL"

# Configures the media uploader to local
config :passwordless, :file_uploads, adapter: Passwordless.FileUploads.Local

# Configures the emails
config :passwordless, :emails,
  auth: [
    name: "Passwordless",
    email: "noreply@auth.eu.passwordlesstools.com",
    domain: "auth.eu.passwordlesstools.com",
    reply_to: "hello@passwordless.tools",
    reply_to_name: "Passwordless Support"
  ],
  support: [
    name: "Passwordless",
    email: "noreply@support.passwordlesstools.com",
    domain: "support.passwordlesstools.com",
    reply_to: "hello@passwordless.tools",
    reply_to_name: "Passwordless Support"
  ],
  alerts: [
    name: "Passwordless Alert",
    email: "noreply@alerts.passwordlesstools.com",
    domain: "alerts.passwordlesstools.com",
    reply_to: "hello@passwordless.tools",
    reply_to_name: "Passwordless Support"
  ]

config :passwordless, :queues, email_notifications: %{sqs_queue_url: ""}

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.23.0",
  default: [
    args: ~w(
      js/app.ts
      --bundle
      --target=esnext
      --outdir=../priv/static/assets
      --external:/fonts/*
      --external:/images/*
      --loader:.ttf=dataurl
      --loader:.woff=dataurl
      --loader:.woff2=dataurl
    ),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :passwordless,
       :error_translator_function,
       {PasswordlessWeb.CoreComponents, :translate_error}

config :passwordless, :translation_helper_module, PasswordlessWeb.PetalFrameworkTranslations

config :tailwind,
  version: "4.1.0",
  default: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ],
  backpex: [
    args: ~w(
      --input=assets/css/backpex.css
      --output=priv/static/assets/backpex.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Specify which languages you support
# To create .po files for a language run `mix gettext.merge priv/gettext --locale fr`
# (fr is France, change to whatever language you want - make sure it's included in the locales config below)
config :passwordless, PasswordlessWeb.Gettext, allowed_locales: ~w(en)

# Social login providers
config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "email profile"]}
  ]

config :flop, repo: Passwordless.Repo, default_limit: 10
config :tesla, :adapter, {Tesla.Adapter.Finch, name: Passwordless.Finch}

# Backpex admin panel
config :backpex, :pubsub_server, Passwordless.PubSub

config :backpex,
  translator_function: {PasswordlessWeb.CoreComponents, :translate_backpex},
  error_translator_function: {PasswordlessWeb.CoreComponents, :translate_error}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

import_config "aws.exs"
import_config "locale.exs"
